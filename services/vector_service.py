from sqlalchemy import text

from backend.db.database import engine



# -----------------------------------
# Convert numpy embedding to pgvector
# -----------------------------------

def embedding_to_vector(embedding):

    return "[" + ",".join(
        map(
            str,
            embedding.tolist()
        )
    ) + "]"




# -----------------------------------
# Duplicate Detection
# -----------------------------------

def check_duplicate_embedding(
    embedding,
    threshold=0.99
):

    vector_str = embedding_to_vector(
        embedding
    )


    query = text("""
        SELECT
            id,
            title,

            1 - (
                embedding <=>
                CAST(:embedding AS vector)
            ) AS similarity


        FROM products


        WHERE embedding IS NOT NULL


        ORDER BY
            embedding <=>
            CAST(:embedding AS vector)


        LIMIT 1
    """)



    with engine.connect() as conn:

        result = conn.execute(
            query,
            {
                "embedding": vector_str
            }
        ).fetchone()



    if not result:

        return {
            "duplicate": False
        }



    similarity = float(
        result.similarity
    )



    if similarity >= threshold:

        return {

            "duplicate": True,

            "id": result.id,

            "title": result.title,

            "similarity": similarity

        }



    return {

        "duplicate": False,

        "similarity": similarity

    }





# -----------------------------------
# Exact Product Match
# -----------------------------------

def get_exact_match(
    embedding,
    threshold=0.90
):

    vector_str = embedding_to_vector(
        embedding
    )


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
            local_image_path,


            1 - (
                embedding <=>
                CAST(:embedding AS vector)
            ) AS similarity


        FROM products


        WHERE embedding IS NOT NULL


        ORDER BY
            embedding <=>
            CAST(:embedding AS vector)


        LIMIT 1

    """)



    with engine.connect() as conn:

        result = conn.execute(
            query,
            {
                "embedding": vector_str
            }
        ).fetchone()



    if not result:

        return None



    similarity = float(
        result.similarity
    )



    if similarity < threshold:

        return None



    return dict(
        result._mapping
    )






# -----------------------------------
# Hybrid Ranking Search
# -----------------------------------

def hybrid_search_products(
    embedding,
    limit=20,
    final_limit=10
):


    vector_str = embedding_to_vector(
        embedding
    )



    query = text("""
    
    WITH vector_results AS (

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
            local_image_path,


            1 - (
                embedding <=>
                CAST(:embedding AS vector)
            ) AS clip_score



        FROM products



        WHERE embedding IS NOT NULL



        ORDER BY

            embedding <=>
            CAST(:embedding AS vector)



        LIMIT :limit

    )



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
        local_image_path,


        clip_score,


        (
            clip_score * 0.85

        ) AS final_score



    FROM vector_results



    ORDER BY

        final_score DESC



    LIMIT :final_limit

    """)



    with engine.connect() as conn:


        rows = conn.execute(
            query,
            {

                "embedding": vector_str,

                "limit": limit,

                "final_limit": final_limit

            }
        )



        return [

            dict(row._mapping)

            for row in rows

        ]



def get_candidate_products(
    embedding,
    limit=50
):

    vector_str = embedding_to_vector(
        embedding
    )



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
            local_image_path,

            1 - (
                embedding <=>
                CAST(:embedding AS vector)
            ) AS clip_score


        FROM products


        WHERE embedding IS NOT NULL


        ORDER BY
            embedding <=>
            CAST(:embedding AS vector)


        LIMIT :limit

    """)



    with engine.connect() as conn:

        rows = conn.execute(
            query,
            {
                "embedding": vector_str,
                "limit": limit
            }
        )



        return [
            dict(row._mapping)
            for row in rows
        ]

# -----------------------------------
# Old Search (keep for backup)
# -----------------------------------

def search_similar_products(
    embedding,
    limit=10,
    similarity_threshold=0.65
):

    vector_str = embedding_to_vector(
        embedding
    )


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
            local_image_path,


            1 - (
                embedding <=>
                CAST(:embedding AS vector)
            ) AS similarity



        FROM products



        WHERE embedding IS NOT NULL



        AND
        (
            1 - (
                embedding <=>
                CAST(:embedding AS vector)
            )
        ) >= :threshold



        ORDER BY

            embedding <=>
            CAST(:embedding AS vector)



        LIMIT :limit

    """)



    with engine.connect() as conn:

        rows = conn.execute(
            query,
            {

                "embedding": vector_str,

                "limit": limit,

                "threshold": similarity_threshold

            }
        )


        return [

            dict(row._mapping)

            for row in rows

        ]