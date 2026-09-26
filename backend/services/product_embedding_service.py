import uuid
from pathlib import Path

from sqlalchemy import text

from backend.db.database import engine
from backend.services.clip_service import generate_image_embedding


def insert_product(
    title,
    price,
    platform,
    image_path
):
    with open(image_path, "rb") as f:
        embedding = generate_image_embedding(f)

    vector_str = "[" + ",".join(
        map(str, embedding.tolist())
    ) + "]"

    query = text("""
        INSERT INTO products(
            id,
            title,
            price,
            platform,
            image_url,
            embedding
        )
        VALUES(
            :id,
            :title,
            :price,
            :platform,
            :image_url,
            CAST(:embedding AS vector)
        )
    """)

    with engine.begin() as conn:
        conn.execute(
            query,
            {
                "id": str(uuid.uuid4()),
                "title": title,
                "price": price,
                "platform": platform,
                "image_url": image_path,
                "embedding": vector_str
            }
        )