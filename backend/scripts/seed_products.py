import sys
from pathlib import Path

from backend.services.product_embedding_service import (
    insert_product
)

# Resolved from this file so the script works from any working directory.
PRODUCT_DIR = (
    Path(__file__).resolve().parent.parent / "data" / "products_test"
)

for image_path in PRODUCT_DIR.glob("*.jpg"):

    title = image_path.stem

    print(f"Processing: {title}")

    insert_product(
        title=title,
        price=0,
        platform="local",
        image_path=str(image_path)
    )

print("Done.")