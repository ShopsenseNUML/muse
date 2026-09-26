from sqlalchemy import text

from backend.db.database import engine


from backend.services.metadata_ranker import (
    calculate_metadata_score
)

from backend.services.text_ranker import (
    calculate_text_score
)

from backend.services.unified_ranker import (
    rank_final_products
)



def search_by_metadata(
    analysis,
    limit=50
):


    # -----------------------------
    # Extract query intelligence
    # -----------------------------

    brand = analysis.get(
        "brand"
    )

    category = analysis.get(
        "category"
    )

    max_price = analysis.get(
        "max_price"
    )



    # -----------------------------
    # Candidate retrieval
    # -----------------------------

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


        WHERE


        (
            :category IS NULL

            OR

            category = :category
        )


        AND


        (
            :brand IS NULL

            OR

            LOWER(brand)
            =
            LOWER(:brand)
        )


        AND


        (
            :max_price IS NULL

            OR

            price <= :max_price
        )


        LIMIT :limit

    """)



    with engine.connect() as conn:


        rows = conn.execute(

            query,

            {

                "category": category,

                "brand": brand,

                "max_price": max_price,

                "limit": limit

            }

        ).fetchall()



    products = [

        dict(row._mapping)

        for row in rows

    ]



    # -----------------------------
    # Metadata Intelligence Scoring
    # -----------------------------


    for product in products:


        # Temporary popularity
        # Later replace with real click/order data

        product["popularity_score"] = 50



        product["metadata_score"] = (
            calculate_metadata_score(
                product,
                analysis
            )
        )
        product["text_score"] = calculate_text_score(
          product,
          analysis
          )



    # -----------------------------
    # Unified Ranking
    # -----------------------------


    ranked_products = rank_final_products(
        products
    )



    return ranked_products[:10]