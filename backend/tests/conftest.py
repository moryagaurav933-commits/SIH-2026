"""
Pytest bootstrap for the Krishi-Saarthi backend.

The test suite asserts on real seeded data (farmers, mandi prices, weather,
disease telemetry, ...). Without this file, `pytest` against a brand new clone
fails with "no such table" / empty-response errors because it creates the schema
but never inserts any rows.

Running `python scripts/init_db.py` first makes the tests pass, but that is an
easy step to forget and it differs per machine, so we do it automatically here.
The seeding is idempotent: it detects complete data and skips.
"""
import os
import sys

import pytest

BACKEND_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if BACKEND_DIR not in sys.path:
    sys.path.insert(0, BACKEND_DIR)


def _ensure_database():
    """Create tables and seed demo data if the database is missing or empty."""
    scripts_dir = os.path.join(BACKEND_DIR, "scripts")
    if scripts_dir not in sys.path:
        sys.path.insert(0, scripts_dir)

    import asyncio

    from init_db import init_and_seed

    try:
        asyncio.run(init_and_seed())
    except SystemExit:
        raise
    except Exception as exc:  # pragma: no cover - surfaced by the tests anyway
        pytest.exit(f"[conftest] database setup failed: {exc}", returncode=1)


@pytest.fixture(scope="session", autouse=True)
def _database_ready():
    _ensure_database()
    yield


@pytest.fixture(scope="session")
def anyio_backend():
    return "asyncio"
