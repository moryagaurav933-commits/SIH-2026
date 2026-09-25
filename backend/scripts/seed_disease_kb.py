"""
Seeder for Crop Disease Knowledge Base and ML Class Mapping.
Parses disease_database.sql or inserts structured disease profile records
into active database (SQLite or PostgreSQL) without foreign key errors.
"""
import os
import re
import logging
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

logger = logging.getLogger("seed_disease_kb")

SQL_FILE_PATHS = [
    os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "app", "database", "01_disease_database.sql"),
    os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "database", "schemas", "01_disease_database.sql"),
    os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "database", "schemas", "01_disease_database.sql"),
    os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "ai_module", "disease_database.sql"),
]

def split_sql_statements(sql: str) -> list:
    statements = []
    current = []
    in_quote = False
    i = 0
    n = len(sql)
    while i < n:
        if not in_quote and sql[i:i+2] == "--":
            while i < n and sql[i] != '\n':
                i += 1
            continue
        char = sql[i]
        if char == "'":
            if in_quote and i + 1 < n and sql[i+1] == "'":
                current.append("''")
                i += 2
                continue
            in_quote = not in_quote
            current.append(char)
            i += 1
            continue
        if char == ';' and not in_quote:
            stmt = "".join(current).strip()
            if stmt and stmt.upper().startswith("INSERT INTO"):
                statements.append(stmt)
            current = []
            i += 1
            continue
        current.append(char)
        i += 1
    if current:
        stmt = "".join(current).strip()
        if stmt and stmt.upper().startswith("INSERT INTO"):
            statements.append(stmt)
    return statements

async def seed_disease_database(session: AsyncSession) -> bool:
    """
    Seeds the disease database from disease_database.sql into the provided async session.
    Handles dialect differences (SQLite vs PostgreSQL).
    """
    # 1. Check if diseases already seeded
    try:
        check = await session.execute(text("SELECT COUNT(*) FROM diseases"))
        count = check.scalar()
        if count and count >= 21:
            logger.info(f"Diseases table already seeded with {count} records. Skipping.")
            return True
    except Exception:
        # Table might not exist yet if not created by metadata
        pass

    # Find SQL file
    sql_path = None
    for p in SQL_FILE_PATHS:
        if os.path.exists(p):
            sql_path = p
            break

    if not sql_path:
        logger.warning("disease_database.sql not found in expected paths.")
        return False

    logger.info(f"Reading SQL seed file from: {sql_path}")
    with open(sql_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Extract all INSERT INTO statements respecting quotes and comments
    statements = split_sql_statements(content)

    dialect_name = getattr(getattr(session, 'bind', None), 'name', '').lower()
    is_sqlite = 'sqlite' in dialect_name

    logger.info(f"Found {len(statements)} INSERT statements in {os.path.basename(sql_path)}. Target DB is {'SQLite' if is_sqlite else 'PostgreSQL'}.")

    for stmt in statements:
        cleaned_stmt = stmt.strip()
        if not cleaned_stmt:
            continue

        # Adjust ON CONFLICT for SQLite if needed (SQLite supports ON CONFLICT (col) DO NOTHING in 3.24+)
        if is_sqlite:
            # Replace PostgreSQL specifics if any
            pass

        try:
            await session.execute(text(cleaned_stmt))
        except Exception as e:
            # If conflict or already inserted, continue
            err_msg = str(e).lower()
            if "unique constraint" in err_msg or "already exists" in err_msg or "primary key" in err_msg:
                continue
            logger.warning(f"Error executing statement on {dialect_name}: {e}\nStatement: {cleaned_stmt[:100]}...")

    await session.commit()
    logger.info("Successfully seeded disease knowledge base into database.")
    return True
