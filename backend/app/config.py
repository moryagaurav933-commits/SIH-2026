from pathlib import Path
"""
Krishi-Saarthi Backend Configuration
Pydantic Settings for all environment variables
"""
from pydantic_settings import BaseSettings
from functools import lru_cache
from typing import Annotated, Any
from pydantic import BeforeValidator


def _as_bool(v: Any) -> Any:
    """Parse booleans leniently.

    Settings like DEBUG / MINIO_USE_SSL use very generic names, so they can be
    shadowed by ambient OS or shell environment variables (e.g. a machine-wide
    DEBUG=release exported on Windows). Instead of crashing the whole app on
    startup, normalise the common truthy/falsy spellings.
    """
    if isinstance(v, bool):
        return v
    if isinstance(v, str):
        val = v.strip().lower()
        if val in {"1", "true", "t", "yes", "y", "on"}:
            return True
        if val in {"0", "false", "f", "no", "n", "off", "release", "prod", "production", ""}:
            return False
    return v


LooseBool = Annotated[bool, BeforeValidator(_as_bool)]


class Settings(BaseSettings):
    # ─── Application ───
    APP_NAME: str = "Krishi-Saarthi API"
    APP_VERSION: str = "1.0.0"
    DEBUG: LooseBool = True

    # ─── Database ───
    DATABASE_URL: str = "postgresql+asyncpg://krishi_admin:krishi_secure_2026@localhost:5433/krishi_saarthi_master"
    DATABASE_URL_SYNC: str = "postgresql+psycopg2://krishi_admin:krishi_secure_2026@localhost:5433/krishi_saarthi_master"

    # ─── Redis ───
    REDIS_URL: str = "redis://localhost:6379/0"

    # ─── Security ───
    SECRET_KEY: str = "krishi-saarthi-super-secret-jwt-key-change-in-production-2026"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 10080  # 7 days

    # ─── External APIs ───
    WEATHER_API_KEY: str = ""
    OPENWEATHER_API_KEY: str = ""
    IMD_API_KEY: str = ""
    IMD_API_URL: str = "https://api.imd.gov.in/v1"
    AGMARKNET_API_KEY: str = ""
    AGMARKNET_API_URL: str = "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070"
    OGD_API_KEY: str = ""

    # ─── AI & Basemaps ───
    GEMINI_API_KEY: str = ""
    GEMINI_RATE_LIMIT_PER_HOUR: int = 999999
    CARTO_API_KEY: str = ""
    CARTO_RATE_LIMIT_PER_HOUR: int = 15

    # ─── USSD ───
    USSD_SHORT_CODE: str = "*123#"
    USSD_GATEWAY_URL: str = ""

    # ─── MinIO (S3-compatible) ───
    MINIO_ENDPOINT: str = "localhost:9000"
    MINIO_ACCESS_KEY: str = "krishiminio"
    MINIO_SECRET_KEY: str = "minio_secure_2026"
    MINIO_BUCKET: str = "krishi-saarthi"
    MINIO_USE_SSL: LooseBool = False

    # ─── Kriging ───
    KRIGING_GRID_SIZE: int = 100
    KRIGING_PREDICTION_HOURS: int = 72

    # ─── Celery ───
    CELERY_BROKER_URL: str = "redis://localhost:6379/1"
    CELERY_RESULT_BACKEND: str = "redis://localhost:6379/2"

    # ─── CORS ───
    CORS_ORIGINS: list[str] = ["*"]

    class Config:
        # Check both local and parent directory for .env files
        _this_dir = Path(__file__).resolve().parent
        _backend_env = _this_dir.parent / ".env"
        _root_env = _this_dir.parent.parent / ".env"
        env_file = (str(_backend_env), str(_root_env), ".env", "backend/.env", "../.env")
        env_file_encoding = "utf-8"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    cfg = Settings()
    # Security check: alert if insecure placeholder key is used in production
    if not cfg.DEBUG and ("change-in-production" in cfg.SECRET_KEY or "super-secret" in cfg.SECRET_KEY):
        import logging
        logging.getLogger("security").critical(
            "CRITICAL SECURITY RISK: Insecure default SECRET_KEY detected in production mode! "
            "Please set a cryptographically secure SECRET_KEY in your environment."
        )
    return cfg


settings = get_settings()
