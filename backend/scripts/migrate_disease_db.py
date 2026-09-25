"""
Database Migration and Health Check CLI for Crop AI & Disease Knowledge Base.
Migrates disease_database.sql and seeds all 9 tables across PostgreSQL and SQLite.
Verifies all 4 crops, 21 diseases, child tables, and ML class mappings.
"""
import sys
import os
import asyncio
import logging

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import text, select

from app.config import settings
from app.db.base import Base
from app.models.crop_disease import (
    Crop, Disease, DiseaseSymptom, HealthySign,
    FavorableCondition, Treatment, PreventionStep, Source, MLClassMapping
)
from scripts.seed_disease_kb import seed_disease_database

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("migrate_disease_db")

async def verify_database(session: AsyncSession, engine_name: str) -> bool:
    print(f"\n========================================================")
    print(f"  Verifying Disease Knowledge Base on {engine_name}")
    print(f"========================================================")

    # 1. Crops
    crops_res = await session.execute(text("SELECT COUNT(*) FROM crops"))
    crop_count = crops_res.scalar()
    print(f"  [+] Crops seeded: {crop_count} (Expected: 4)")

    # 2. Diseases
    diseases_res = await session.execute(text("SELECT COUNT(*) FROM diseases"))
    disease_count = diseases_res.scalar()
    print(f"  [+] Master Diseases seeded: {disease_count} (Expected: 21)")

    # 3. Child tables
    symp_count = (await session.execute(text("SELECT COUNT(*) FROM disease_symptoms"))).scalar()
    treat_count = (await session.execute(text("SELECT COUNT(*) FROM treatments"))).scalar()
    prev_count = (await session.execute(text("SELECT COUNT(*) FROM prevention_steps"))).scalar()
    cond_count = (await session.execute(text("SELECT COUNT(*) FROM favorable_conditions"))).scalar()
    src_count = (await session.execute(text("SELECT COUNT(*) FROM sources"))).scalar()
    hs_count = (await session.execute(text("SELECT COUNT(*) FROM healthy_signs"))).scalar()
    ml_count = (await session.execute(text("SELECT COUNT(*) FROM ml_class_mapping"))).scalar()

    print(f"  [+] Disease Symptoms: {symp_count}")
    print(f"  [+] Treatments: {treat_count}")
    print(f"  [+] Prevention Steps: {prev_count}")
    print(f"  [+] Favorable Conditions: {cond_count}")
    print(f"  [+] Verified Sources: {src_count}")
    print(f"  [+] Healthy Signs: {hs_count}")
    print(f"  [+] ML Class Mappings: {ml_count} (Expected: 21)")

    # 4. Spot check a disease profile
    spot_res = await session.execute(text("""
        SELECT d.disease_id, d.disease_name, c.crop_name, d.severity
        FROM diseases d
        JOIN crops c ON d.crop_id = c.crop_id
        WHERE d.disease_id = 'tomato_early_blight'
    """))
    row = spot_res.fetchone()
    if row:
        print(f"  [+] Spot Check Passed: {row[1]} ({row[2]}) - Severity: {row[3]}")
    else:
        print(f"  [-] Spot Check Failed for tomato_early_blight")
        return False

    success = (crop_count >= 4 and disease_count >= 21 and ml_count >= 21)
    if success:
        print(f"  [SUCCESS] All tables successfully populated on {engine_name}!")
    else:
        print(f"  [WARNING] Partial seed detected on {engine_name}.")
    return success

async def run_migration(db_url: str, label: str):
    print(f"\n[+] Connecting to {label}: {db_url}")
    is_sqlite = "sqlite" in db_url
    engine_kwargs = {"echo": False}
    if is_sqlite:
        engine_kwargs["connect_args"] = {"check_same_thread": False}

    try:
        engine = create_async_engine(db_url, **engine_kwargs)
        async with engine.begin() as conn:
            # Create all tables (including crop_disease tables)
            await conn.run_sync(Base.metadata.create_all)

        async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
        async with async_session() as session:
            await seed_disease_database(session)
            await verify_database(session, label)

        await engine.dispose()
    except Exception as e:
        print(f"[-] Migration skipped or failed for {label}: {e}")

async def main():
    print("========================================================")
    print("  Krishi-Saarthi: Disease Database Migration & Verification")
    print("========================================================")
    
    # 1. Migrate settings.DATABASE_URL (Active DB, e.g. SQLite or configured DB)
    await run_migration(settings.DATABASE_URL, "Active Application Database")

    # 2. If PostgreSQL container URL is distinct, also attempt PostgreSQL migration
    pg_url = os.getenv("PG_DATABASE_URL", "postgresql+asyncpg://krishi_admin:krishi_secure_2026@localhost:5433/krishi_saarthi_master")
    if pg_url != settings.DATABASE_URL:
        await run_migration(pg_url, "Docker PostgreSQL Instance (Port 5433)")

if __name__ == "__main__":
    asyncio.run(main())
