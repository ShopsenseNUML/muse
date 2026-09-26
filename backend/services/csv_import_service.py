import csv
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

    ON CONFLICT DO NOTHING
""")



def safe_price(value):

    try:
        return float(value)

    except:
        return 0



def import_csv(csv_path):

    count = 0


    with open(
        csv_path,
        newline="",
        encoding="utf-8"
    ) as file:


        reader = csv.DictReader(file)



        with engine.begin() as conn:


            for row in reader:


                try:


                    params = {

                        "id": str(
                            uuid.uuid4()
                        ),


                        "title": (
                            row.get("title")
                            or ""
                        ).strip(),


                        "brand": (
                            row.get("brand")
                            or "Unknown"
                        ).strip(),


                        "category": (
                            row.get("category")
                            or "Unknown"
                        ).strip(),


                        "description": (
                            row.get("description")
                            or ""
                        ).strip(),


                        "price": safe_price(
                            row.get("price")
                        ),


                        "platform": (
                            row.get("platform")
                            or "Unknown"
                        ).strip(),


                        "source_url": (
                            row.get("source_url")
                            or ""
                        ).strip(),


                        "image_url": (
                            row.get("image_url")
                            or ""
                        ).strip()

                    }



                    conn.execute(
                        INSERT_RAW_QUERY,
                        params
                    )


                    print(
                        "Raw inserted:",
                        params["title"]
                    )


                    count += 1



                except Exception as e:


                    print(
                        "Failed:",
                        row.get("title"),
                        e
                    )



    return count