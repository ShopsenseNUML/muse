from fastapi import APIRouter
from sqlalchemy import text

from backend.db.database import engine
from backend.services.roman_urdu_service import (
    dictionary_stats
)

router = APIRouter(
    prefix="/admin",
    tags=["Admin"]
)


@router.get("/pipeline/stats")
def pipeline_stats():

    query = text("""
        SELECT
            status,
            COUNT(*) as total
        FROM products_raw
        GROUP BY status
    """)

    stats = {
        "pending": 0,
        "downloading": 0,
        "downloaded": 0,
        "embedding": 0,
        "embedded": 0,
        "indexed": 0,
        "failed": 0
    }

    with engine.connect() as conn:

        rows = conn.execute(query)

        for row in rows:

            stats[row.status] = row.total

    return stats


@router.get("/catalog/stats")
def catalog_stats():
    """
    High-level catalog counts for the searchable products table.
    """

    query = text("""
        SELECT
            COUNT(*) AS total,
            COUNT(embedding) AS embedded,
            COUNT(DISTINCT category) AS categories,
            COUNT(DISTINCT platform) AS platforms
        FROM products
    """)

    with engine.connect() as conn:

        row = conn.execute(query).fetchone()

    if not row:

        return {
            "total": 0,
            "embedded": 0,
            "categories": 0,
            "platforms": 0
        }

    return {
        "total": row.total,
        "embedded": row.embedded,
        "categories": row.categories,
        "platforms": row.platforms
    }


@router.get("/dictionary/stats")
def dictionary_stats_endpoint():
    """
    Report on the Roman Urdu -> English dictionary.
    Used to verify PDF objective #3 (200+ terms).
    """
    return dictionary_stats()
