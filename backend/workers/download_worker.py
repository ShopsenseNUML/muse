import os
import uuid
from pathlib import Path

import requests

from sqlalchemy import text

from backend.db.database import engine


# Resolved from this file so the worker works from any working directory.
DOWNLOAD_FOLDER = str(
    Path(__file__).resolve().parent.parent / "data" / "downloads"
)


os.makedirs(
    DOWNLOAD_FOLDER,
    exist_ok=True
)


def detect_extension(url, content_type):

    if "webp" in content_type:
        return ".webp"

    if "png" in content_type:
        return ".png"

    if "avif" in content_type:
        return ".avif"

    if "jpeg" in content_type or "jpg" in content_type:
        return ".jpg"

    return ".jpg"



def process_pending_downloads():


    query = text("""
        SELECT
            id,
            title,
            image_url

        FROM products_raw

        WHERE status='pending'

        LIMIT 50
    """)



    with engine.connect() as conn:

        rows = conn.execute(
            query
        ).fetchall()



    print(
        "Pending downloads:",
        len(rows)
    )



    downloaded = 0



    for product in rows:


        try:

            url = product.image_url


            headers = {
                "User-Agent":
                "Mozilla/5.0"
            }



            response = requests.get(
                url,
                headers=headers,
                timeout=30
            )


            response.raise_for_status()



            content_type = response.headers.get(
                "Content-Type",
                ""
            )



            extension = detect_extension(
                url,
                content_type
            )



            filename = (
                str(uuid.uuid4())
                +
                extension
            )



            filepath = os.path.join(
                DOWNLOAD_FOLDER,
                filename
            )



            with open(
                filepath,
                "wb"
            ) as f:

                f.write(
                    response.content
                )



            update = text("""
                UPDATE products_raw

                SET

                    local_image_path=:path,

                    status='downloaded',

                    downloaded_at=NOW()

                WHERE id=:id
            """)



            with engine.begin() as conn:

                conn.execute(
                    update,
                    {
                        "path": filepath,
                        "id": product.id
                    }
                )



            downloaded += 1


            print(
                "Downloaded:",
                product.title
            )



        except Exception as e:


            print(
                "Failed:",
                product.title,
                e
            )



            fail = text("""
                UPDATE products_raw

                SET

                    status='failed',

                    failure_reason=:reason

                WHERE id=:id
            """)


            with engine.begin() as conn:

                conn.execute(
                    fail,
                    {
                        "reason": str(e),
                        "id": product.id
                    }
                )



    return downloaded




if __name__ == "__main__":

    total = process_pending_downloads()


    print(
        "\nTotal downloaded:",
        total
    )