from sqlalchemy import text

from backend.db.database import engine


def create_vector_index():

    query = text("""
        CREATE INDEX IF NOT EXISTS
        products_embedding_hnsw_idx

        ON products

        USING hnsw
        (
            embedding vector_cosine_ops
        )
    """)


    with engine.begin() as conn:

        conn.execute(query)


    print(
        "HNSW vector index created"
    )



def drop_vector_index():

    query = text("""
        DROP INDEX IF EXISTS
        products_embedding_hnsw_idx
    """)


    with engine.begin() as conn:

        conn.execute(query)


    print(
        "Vector index dropped"
    )



def analyze_products_table():

    query = text("""
        ANALYZE products
    """)


    with engine.begin() as conn:

        conn.execute(query)


    print(
        "Products table analyzed"
    )



def rebuild_vector_index():

    drop_vector_index()

    create_vector_index()

    analyze_products_table()

    print(
        "Vector index rebuilt"
    )