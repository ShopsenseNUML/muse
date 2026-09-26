from sqlalchemy import text

from backend.db.database import engine



def finalize_products():

    print(
        "Starting product finalization..."
    )


    # ---------------------------------
    # 1. Move embedded products
    # ---------------------------------

    insert_query = text("""
        INSERT INTO products
        (
            id,
            title,
            brand,
            category,
            description,
            price,
            platform,
            source_url,
            original_image_url,
            local_image_path,
            embedding,
            created_at
        )

        SELECT
            id::text,
            title,
            brand,
            category,
            description,
            price,
            platform,
            source_url,
            image_url,
            local_image_path,
            embedding,
            NOW()

        FROM products_raw

        WHERE
            status='embedded'

        ON CONFLICT (id)
        DO NOTHING

    """)



    with engine.begin() as conn:


        result = conn.execute(
            insert_query
        )


        print(
            "Moved products:",
            result.rowcount
        )



    # ---------------------------------
    # 2. Remove invalid products
    # ---------------------------------

    with engine.begin() as conn:


        result = conn.execute(
            text("""
                DELETE FROM products

                WHERE
                local_image_path IS NULL

                OR local_image_path=''
            """)
        )


        print(
            "Removed missing images:",
            result.rowcount
        )



    # ---------------------------------
    # 3. Remove missing embeddings
    # ---------------------------------

    with engine.begin() as conn:


        result = conn.execute(
            text("""
                DELETE FROM products

                WHERE embedding IS NULL
            """)
        )


        print(
            "Removed missing embeddings:",
            result.rowcount
        )



    # ---------------------------------
    # 4. Normalize brand
    # ---------------------------------

    with engine.begin() as conn:


        conn.execute(
            text("""
                UPDATE products

                SET brand='Unknown'

                WHERE
                brand IS NULL

                OR brand=''
            """)
        )



    # ---------------------------------
    # 5. Normalize category
    # ---------------------------------

    with engine.begin() as conn:


        conn.execute(
            text("""
                UPDATE products

                SET category='Unknown'

                WHERE
                category IS NULL

                OR category=''
            """)
        )



    # ---------------------------------
    # 6. Final count
    # ---------------------------------

    with engine.connect() as conn:


        count = conn.execute(
            text("""
                SELECT COUNT(*)
                FROM products
            """)
        ).scalar()



    print(
        "Final products:",
        count
    )



if __name__ == "__main__":

    finalize_products()