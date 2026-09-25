"""
SQLAlchemy async engine and base model.
Supports auto-fallback to SQLite when PostgreSQL is offline.
"""
import sys
import os
import socket
from pathlib import Path
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import DeclarativeBase, sessionmaker
from sqlalchemy.pool import NullPool
from app.config import settings

def _is_tcp_port_open(host: str, port: int, timeout: float = 0.5) -> bool:
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return True
    except (socket.timeout, OSError):
        return False

backend_dir = Path(__file__).resolve().parent.parent.parent
db_url = settings.DATABASE_URL

# Auto-detect if PostgreSQL is specified but unreachable -> fallback to SQLite
if "postgresql" in db_url and ("localhost" in db_url or "127.0.0.1" in db_url):
    port = 5432
    if ":5433" in db_url:
        port = 5433
    elif ":5432" in db_url:
        port = 5432

    if os.getenv("USE_SQLITE", "").lower() in ("1", "true") or not _is_tcp_port_open("127.0.0.1", port, timeout=0.3):
        sqlite_path = backend_dir / "krishi_saarthi.db"
        db_url = f"sqlite+aiosqlite:///{sqlite_path}"

# Normalize SQLite database path to ensure seamless resolution from root or backend directories
if "sqlite" in db_url and ":///" in db_url:
    db_file = db_url.split(":///")[-1]
    if not db_file.startswith("/"):
        clean_name = Path(db_file.lstrip("./")).name
        abs_path = backend_dir / clean_name
        driver = db_url.split(":///")[0]
        db_url = f"{driver}:///{abs_path}"

engine_kwargs = {"echo": settings.DEBUG}

if "sqlite" in db_url:
    engine_kwargs["connect_args"] = {"check_same_thread": False}
elif "pytest" in sys.modules or os.getenv("TESTING") == "1":
    engine_kwargs["poolclass"] = NullPool
else:
    engine_kwargs.update({
        "pool_size": 20,
        "max_overflow": 10,
        "pool_pre_ping": True,
    })

engine = create_async_engine(
    db_url,
    **engine_kwargs
)

AsyncSessionLocal = sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

class Base(DeclarativeBase):
    """Base class for all SQLAlchemy models."""
    pass
