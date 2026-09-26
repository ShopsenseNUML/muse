"""Seed 5 sample products with real CLIP embeddings.

Run from the repo root:
    NO_PROXY="localhost,127.0.0.1,::1" HF_HUB_OFFLINE=1 \
        .venv/bin/python -m backend.scripts.seed_sample_products
"""
from pathlib import Path
from urllib.parse import quote

from sqlalchemy import text

from backend.db.database import engine
from backend.services.clip_service import generate_image_embedding
from backend.services.vector_service import embedding_to_vector

DATA_DIR = (
    Path(__file__).resolve().parent.parent / "data" / "products"
)
# Served by the Flutter web build's http.server on :8080
IMG_BASE = "http://127.0.0.1:8080/seed_images"

SAMPLES = [
    (
        "Nike Dunk Low Panda.jpg",
        "Nike Dunk Low Panda Sneakers",
        "Nike", "Shoes",
        "Classic Nike Dunk Low in black and white panda colorway.",
        22999.0, "Daraz",
    ),
    (
        "Apple AirPods 4.jpg",
        "Apple AirPods 4 Wireless Earbuds",
        "Apple", "Electronics",
        "Apple AirPods 4 with USB-C charging case.",
        54999.0, "Telemart",
    ),
    (
        "Amazfit GTR 4.jpg",
        "Amazfit GTR 4 Smart Watch",
        "Amazfit", "Smart Watch",
        "Amazfit GTR 4 with AMOLED display and GPS.",
        42999.0, "Daraz",
    ),
    (
        "Acid Wash Tee.jpg",
        "Acid Wash Cotton T-Shirt",
        "Generic", "Clothing",
        "Casual acid wash cotton t-shirt.",
        1499.0, "Telemart",
    ),
    (
        "Arctic Hunter B00350.jpg",
        "Arctic Hunter B00350 Backpack",
        "Arctic Hunter", "Bags",
        "Arctic Hunter B00350 laptop backpack, water resistant.",
        8999.0, "Daraz",
    ),
]

INSERT = text("""
    INSERT INTO products
        (id, title, brand, category, description, price, platform,
         source_url, original_image_url, local_image_path, embedding)
    VALUES
        (:id, :title, :brand, :category, :description, :price, :platform,
         :source_url, :original_image_url, :local_image_path,
         CAST(:embedding AS vector))
    ON CONFLICT (id) DO NOTHING
""")


def main():
    with engine.begin() as conn:
        for i, (fname, title, brand, category, desc, price, platform) in enumerate(
            SAMPLES, start=1
        ):
            path = f"{DATA_DIR}/{fname}"
            with open(path, "rb") as f:
                emb = generate_image_embedding(f)
            vec = embedding_to_vector(emb)
            conn.execute(
                INSERT,
                {
                    "id": f"seed-{i:03d}",
                    "title": title,
                    "brand": brand,
                    "category": category,
                    "description": desc,
                    "price": price,
                    "platform": platform,
                    "source_url": "",
                    "original_image_url": f"{IMG_BASE}/{quote(fname)}",
                    "local_image_path": path,
                    "embedding": vec,
                },
            )
            print(f"seeded seed-{i:03d}: {title}")

    with engine.connect() as conn:
        count = conn.execute(text("SELECT COUNT(*) FROM products")).scalar()
        print(f"products table now has {count} rows")


if __name__ == "__main__":
    main()
