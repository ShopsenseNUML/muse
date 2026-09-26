"""
Product lookup endpoints (by id, list/browse).

Mountable in backend/main.py when needed. Implemented now so the
catalog is browsable for demos and the file is not empty.
"""

from fastapi import APIRouter

from sqlalchemy import text

from backend.db.database import engine


router = APIRouter(
    prefix="/products",
    tags=["Products"]
)


@router.get("/{product_id}")
def get_product(product_id: str):
    """
    Fetch a single product by id.
    """

    query = text("""
        SELECT
            id,
            title,
            brand,
            category,
            description,
            price,
            platform,
            source_url,
            original_image_url,
            local_image_path
        FROM products
        WHERE id = :product_id
    """)

    with engine.connect() as conn:

        row = conn.execute(
            query,
            {"product_id": product_id}
        ).fetchone()

    if not row:

        return {"error": "Product not found"}

    return dict(row._mapping)


@router.get("/")
def list_products(limit: int = 20):
    """
    List products (most recent first). Useful for browsing.
    """

    query = text("""
        SELECT
            id,
            title,
            brand,
            category,
            price,
            platform,
            original_image_url
        FROM products
        ORDER BY created_at DESC
        LIMIT :limit
    """)

    with engine.connect() as conn:

        rows = conn.execute(
            query,
            {"limit": limit}
        ).fetchall()

    return {
        "count": len(rows),
        "products": [
            dict(row._mapping) for row in rows
        ]
    }
