"""Diagnostic: report row counts per table in the local SQLite database.

Run from the ``backend`` folder:

    ..\\.venv311\\Scripts\\python.exe scripts\\_check_db.py

All counts should be non-zero after running ``scripts/init_db.py`` once. A lone
``1`` where many are expected usually means a previous seed was interrupted;
``scripts/init_db.py`` detects and repairs that automatically.
"""
import sqlite3

conn = sqlite3.connect("krishi_saarthi.db")
for (name,) in conn.execute("select name from sqlite_master where type='table' order by name"):
    try:
        count = conn.execute(f"select count(*) from '{name}'").fetchone()[0]
    except sqlite3.Error as exc:
        count = f"ERR {exc}"
    print(f"{name:40s} {count}")
