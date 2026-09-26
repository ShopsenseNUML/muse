"""
Initialize the ShopSense database schema.

Runs postgres/schema.sql against the configured database. Safe to run
repeatedly: every statement uses IF NOT EXISTS, so it will not destroy
existing data. On a fresh database it creates everything needed for the
MVP to run.

Usage:
    python -m scripts.init_db
"""

from pathlib import Path

from sqlalchemy import text

from backend.db.database import engine


SCHEMA_PATH = (
    Path(__file__).resolve()
    .parent.parent
    / "postgres"
    / "schema.sql"
)


def init_db():

    if not SCHEMA_PATH.exists():

        raise FileNotFoundError(
            f"Schema file not found: {SCHEMA_PATH}"
        )

    sql = SCHEMA_PATH.read_text(
        encoding="utf-8"
    )

    print(
        f"Applying schema from {SCHEMA_PATH}..."
    )

    with engine.begin() as conn:

        conn.execute(text(sql))

    print("Schema applied successfully.")


    # Report current state
    with engine.connect() as conn:

        for table in [
            "products",
            "products_raw",
            "search_logs"
        ]:

            count = conn.execute(
                text(f"SELECT COUNT(*) FROM {table}")
            ).scalar()

            print(
                f"  {table}: {count} rows"
            )


if __name__ == "__main__":

    init_db()
