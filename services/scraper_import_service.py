"""
Persist scraped products into products_raw.

Shared by both scrapers (telemart, amazon) so they feed the existing
ingestion pipeline (download -> embed -> finalize) uniformly.

Each scraped product must already be normalized to the dict shape
produced by the scrapers:
    id, title, brand, category, description, price,
    platform, source_url, image_url
"""

import uuid

from sqlalchemy import text

from backend.db.database import engine


INSERT_RAW_QUERY = text("""
    INSERT INTO products_raw
    (
        id,
        title,
        brand,
        category,
        description,
        price,
        platform,
        source_url,
        image_url,
        status
    )
    VALUES
    (
        :id,
        :title,
        :brand,
        :category,
        :description,
        :price,
        :platform,
        :source_url,
        :image_url,
        'pending'
    )
    ON CONFLICT (id) DO NOTHING
""")


def persist_products(products):
    """
    Insert a list of normalized product dicts into products_raw.
    Returns (inserted, skipped) counts.

    Reuses the scraper's own id when present (Telemart ids are stable
    so re-scraping won't duplicate); otherwise generates a uuid.
    """

    inserted = 0
    skipped = 0

    with engine.begin() as conn:

        for product in products:

            product_id = product.get("id") or str(uuid.uuid4())

            # Cast to string because products_raw.id is a UUID column
            # and scraper ids may arrive as int (Telemart) or str.
            try:

                str_id = str(product_id)

                # Validate it parses as UUID; if not, namespace it.
                uuid.UUID(str_id)

            except (ValueError, AttributeError):

                str_id = str(
                    uuid.uuid5(
                        uuid.NAMESPACE_URL,
                        f"{product['platform']}:{product_id}"
                    )
                )

            result = conn.execute(
                INSERT_RAW_QUERY,
                {
                    "id": str_id,
                    "title": product.get("title") or "Untitled",
                    "brand": product.get("brand") or "Unknown",
                    "category": product.get("category") or "Unknown",
                    "description": product.get("description") or "",
                    "price": float(product.get("price") or 0),
                    "platform": product.get("platform") or "Unknown",
                    "source_url": product.get("source_url") or "",
                    "image_url": product.get("image_url") or ""
                }
            )

            if result.rowcount > 0:

                inserted += 1

            else:

                skipped += 1

    return inserted, skipped
