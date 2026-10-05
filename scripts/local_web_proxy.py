"""Serve the Flutter web build and proxy its API requests to local FastAPI."""

from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen
import json


PROJECT_ROOT = Path(__file__).resolve().parents[1]
WEB_ROOT = PROJECT_ROOT / "mobile_app" / "build" / "web"
BACKEND_ORIGIN = "http://127.0.0.1:8000"
HOST = "127.0.0.1"
PORT = 8080


class LocalWebHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(WEB_ROOT), **kwargs)

    def do_GET(self):
        if self.path == "/__local_proxy_health":
            body = json.dumps({"status": "healthy", "api_proxy": BACKEND_ORIGIN}).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        if self.path.startswith("/api/"):
            self._proxy_api()
            return
        super().do_GET()

    def do_HEAD(self):
        if self.path.startswith("/api/"):
            self._proxy_api()
            return
        super().do_HEAD()

    def do_POST(self):
        self._proxy_api()

    def do_PUT(self):
        self._proxy_api()

    def do_PATCH(self):
        self._proxy_api()

    def do_DELETE(self):
        self._proxy_api()

    def do_OPTIONS(self):
        self._proxy_api()

    def _proxy_api(self):
        if not self.path.startswith("/api/"):
            self.send_error(404, "Only /api routes are proxied")
            return

        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length) if length else None
        excluded = {"host", "connection", "content-length", "accept-encoding"}
        headers = {key: value for key, value in self.headers.items() if key.lower() not in excluded}
        request = Request(
            f"{BACKEND_ORIGIN}{self.path}",
            data=body,
            headers=headers,
            method=self.command,
        )

        try:
            with urlopen(request, timeout=125) as response:
                self._write_upstream_response(response.status, response.headers, response.read())
        except HTTPError as response:
            self._write_upstream_response(response.code, response.headers, response.read())
        except (TimeoutError, URLError, OSError) as exc:
            payload = json.dumps({
                "detail": f"Local diagnosis backend at {BACKEND_ORIGIN} is unavailable: {exc}"
            }).encode()
            self.send_response(502)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)

    def _write_upstream_response(self, status, upstream_headers, body):
        self.send_response(status)
        excluded = {"connection", "transfer-encoding", "content-length", "server", "date"}
        for key, value in upstream_headers.items():
            if key.lower() not in excluded:
                self.send_header(key, value)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(body)


if __name__ == "__main__":
    if not (WEB_ROOT / "index.html").is_file():
        raise SystemExit(f"Flutter web build not found: {WEB_ROOT / 'index.html'}")
    server = ThreadingHTTPServer((HOST, PORT), LocalWebHandler)
    print(f"Serving {WEB_ROOT} and proxying /api/* to {BACKEND_ORIGIN} on http://{HOST}:{PORT}")
    server.serve_forever()
