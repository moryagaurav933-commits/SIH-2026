"""
Backend Vercel / ASGI Entrypoint.
Exposes the FastAPI application instance from app.main.
"""
from app.main import app

__all__ = ["app"]
