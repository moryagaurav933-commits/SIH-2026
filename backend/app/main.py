"""
Krishi-Saarthi FastAPI Application Entry Point
"""
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, HTMLResponse
from fastapi.openapi.docs import get_swagger_ui_html
from fastapi.staticfiles import StaticFiles
from contextlib import asynccontextmanager
from pathlib import Path
import time
import structlog
from sqlalchemy import text
import redis.asyncio as aioredis
import httpx

from app.config import settings
from app.api.v1.router import api_router
from app.db.session import engine
from app.db.base import Base
import app.models  # Register all models with Base
from app.core.exceptions import KrishiSaarthiException

logger = structlog.get_logger()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application startup and shutdown lifecycle."""
    logger.info(
        "starting_application",
        app_name=settings.APP_NAME,
        version=settings.APP_VERSION,
        debug=settings.DEBUG,
    )
    # Auto-initialize database tables
    try:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        logger.info("database_tables_initialized")

        # Ensure Disease Knowledge Base is populated
        try:
            from app.db.base import AsyncSessionLocal
            from scripts.seed_disease_kb import seed_disease_database
            async with AsyncSessionLocal() as session:
                await seed_disease_database(session)
        except Exception as seed_err:
            logger.warning("disease_db_seed_notice", detail=str(seed_err))

    except Exception as e:
        logger.error("database_init_error", error=str(e))
    yield
    await engine.dispose()
    logger.info("shutdown_complete")


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description=(
        "Krishi-Saarthi: Offline-first agricultural intelligence platform. "
        "Provides crop disease diagnosis, weather forecasts, mandi prices, "
        "P2P mesh networking, insurance evidence, and predictive disease mapping."
    ),
    lifespan=lifespan,
    docs_url=None,
    redoc_url="/redoc",
)

# ─── Middleware ───
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:5173",
        "http://127.0.0.1:5173",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
        "http://localhost:8080",
        "http://127.0.0.1:8080",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    """Add X-Process-Time header to all responses."""
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(round(process_time, 4))
    return response


# ─── Exception Handlers ───
@app.exception_handler(KrishiSaarthiException)
async def krishi_exception_handler(request: Request, exc: KrishiSaarthiException):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": exc.error_code,
            "message": exc.message,
            "detail": exc.detail,
        },
    )


# ─── Routes ───
app.include_router(api_router, prefix="/api/v1")

# ─── Core AI Disease Diagnosis Route (POST /api/diagnose) ───
from app.api.v1.endpoints.diagnoses import process_leaf_diagnosis
from app.db.session import get_db
from app.api.deps import get_optional_farmer
from app.models.farmer import Farmer
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import UploadFile, File, Form, Depends
from typing import Optional

@app.post("/api/diagnose", tags=["Crop AI Diagnosis"])
@app.post("/api/v1/diagnose", tags=["Crop AI Diagnosis"])
async def api_diagnose_endpoint(
    request: Request,
    file: Optional[UploadFile] = File(None),
    image: Optional[UploadFile] = File(None),
    image_base64: Optional[str] = Form(None),
    crop_type: Optional[str] = Form(None),
    crop_hint: Optional[str] = Form(None),
    gps_lat: Optional[float] = Form(None),
    gps_lon: Optional[float] = Form(None),
    district_code: Optional[str] = Form(None),
    farmer: Optional[Farmer] = Depends(get_optional_farmer),
    db: AsyncSession = Depends(get_db),
):
    """
    Core AI crop disease diagnosis endpoint: Accepts leaf image upload,
    runs PyTorch MobileNetV3 inference, and queries PostgreSQL for full disease profile.
    """
    return await process_leaf_diagnosis(
        request=request,
        file=file,
        image=image,
        image_base64=image_base64,
        crop_type=crop_type,
        crop_hint=crop_hint,
        gps_lat=gps_lat,
        gps_lon=gps_lon,
        district_code=district_code,
        farmer=farmer,
        db=db,
    )



@app.get("/docs", include_in_schema=False)
async def custom_swagger_ui_html():
    """Custom Swagger UI with Krishi-Saarthi Green & White agricultural theme."""
    html_resp = get_swagger_ui_html(
        openapi_url=app.openapi_url,
        title=f"{settings.APP_NAME} — API Documentation",
        swagger_favicon_url="https://fastapi.tiangolo.com/img/favicon.png",
    )
    custom_style = """<style>
      :root {
        --primary-green: #2E7D32;
        --dark-green: #1B5E20;
        --light-green: #E8F5E9;
        --alert-red: #D32F2F;
        --warn-yellow: #FFA000;
        --deep-black: #0A1A0A;
      }
      .topbar { background-color: var(--deep-black) !important; border-bottom: 3px solid var(--primary-green) !important; padding: 10px 0 !important; }
      .topbar .link { color: #FFFFFF !important; font-weight: 700 !important; font-size: 1.15rem !important; }
      .topbar .link::after { content: "  [कृषि-सारथी API]"; font-size: 0.85rem; color: #A5D6A7; margin-left: 8px; }
      .swagger-ui .info .title { color: var(--dark-green) !important; font-weight: 800 !important; }
      .swagger-ui .info a { color: var(--primary-green) !important; }
      .swagger-ui .opblock.opblock-get { border-color: var(--primary-green) !important; background: rgba(46, 125, 50, 0.05) !important; }
      .swagger-ui .opblock.opblock-get .opblock-summary-method { background: var(--primary-green) !important; }
      .swagger-ui .opblock.opblock-post { border-color: var(--dark-green) !important; background: rgba(27, 94, 32, 0.05) !important; }
      .swagger-ui .opblock.opblock-post .opblock-summary-method { background: var(--dark-green) !important; }
      .swagger-ui .opblock.opblock-put { border-color: var(--warn-yellow) !important; background: rgba(255, 160, 0, 0.05) !important; }
      .swagger-ui .opblock.opblock-put .opblock-summary-method { background: var(--warn-yellow) !important; }
      .swagger-ui .opblock.opblock-delete { border-color: var(--alert-red) !important; background: rgba(211, 47, 47, 0.05) !important; }
      .swagger-ui .opblock.opblock-delete .opblock-summary-method { background: var(--alert-red) !important; }
      .swagger-ui .btn.execute { background-color: var(--primary-green) !important; color: #FFFFFF !important; border-color: var(--primary-green) !important; border-radius: 6px !important; }
      .swagger-ui .btn.authorize { color: var(--primary-green) !important; border-color: var(--primary-green) !important; border-radius: 6px !important; }
      .swagger-ui .btn.authorize svg { fill: var(--primary-green) !important; }
      .swagger-ui .model-title { color: var(--dark-green) !important; }
      .swagger-ui section.models { border-color: #E0EBE0 !important; }
      .swagger-ui section.models.is-open h4 { border-color: #E0EBE0 !important; }
    </style></head>""".encode("utf-8")
    new_body = html_resp.body.replace(b"</head>", custom_style)
    headers = {k: v for k, v in html_resp.headers.items() if k.lower() != "content-length"}
    return HTMLResponse(content=new_body, status_code=html_resp.status_code, headers=headers)


@app.get("/health", tags=["System"])
async def health_check():
    """System health check endpoint verifying PostgreSQL, Redis, and MinIO live."""
    services = {}

    # 1. Database check (PostgreSQL or SQLite auto-fallback)
    is_sqlite = "sqlite" in str(engine.url)
    try:
        async with engine.connect() as conn:
            res = await conn.execute(text("SELECT count(*) FROM farmers"))
            farmers_cnt = res.scalar()
            services["database"] = {
                "status": "connected",
                "engine": "SQLite 3 (Local Auto-Fallback)" if is_sqlite else "PostgreSQL 16",
                "farmers_seeded": farmers_cnt,
            }
            services["postgresql"] = services["database"]
    except Exception as e:
        services["database"] = {"status": "error", "error": str(e)}
        services["postgresql"] = services["database"]

    # 2. Redis check
    try:
        r = aioredis.from_url(settings.REDIS_URL, socket_timeout=2.0)
        pong = await r.ping()
        await r.close()
        services["redis"] = {
            "status": "connected" if pong else "unresponsive",
            "url": settings.REDIS_URL,
            "port": 6379,
            "ping": "PONG" if pong else "FAIL"
        }
    except Exception as e:
        services["redis"] = {"status": "error", "error": str(e)}

    # 3. MinIO check
    try:
        async with httpx.AsyncClient(timeout=2.0) as client:
            minio_resp = await client.get(f"http://{settings.MINIO_ENDPOINT}/minio/health/live")
            services["minio"] = {
                "status": "connected" if minio_resp.status_code == 200 else f"http_{minio_resp.status_code}",
                "endpoint": settings.MINIO_ENDPOINT,
                "console_port": 9001,
                "bucket": settings.MINIO_BUCKET,
            }
    except Exception as e:
        services["minio"] = {"status": "error", "error": str(e)}

    all_healthy = all(s.get("status") == "connected" for s in services.values())
    return {
        "status": "healthy" if all_healthy else "degraded",
        "version": settings.APP_VERSION,
        "app": settings.APP_NAME,
        "services": services
    }


@app.get("/", tags=["System"])
async def root():
    """Root endpoint with API information and application links."""
    return {
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "flutter_mobile_app": "/app",
        "docs": "/docs",
        "health": "/health",
        "api": "/api/v1",
    }


# ─── Mount Flutter Web App as Static Files at /app ───
mobile_web_path = Path(__file__).resolve().parent.parent.parent / "mobile_app" / "build" / "web"
if mobile_web_path.exists():
    app.mount("/app", StaticFiles(directory=str(mobile_web_path), html=True), name="mobile_web_app")


