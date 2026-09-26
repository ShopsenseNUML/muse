from backend.db.database import engine

from backend.services.clip_service import (
    generate_image_embedding
)

from sqlalchemy import text



def embedding_to_vector(embedding):

    return "[" + ",".join(
        map(
            str,
            embedding.tolist()
        )
    ) + "]"





def process_embeddings():


    query = text("""
        SELECT
            id,
            title,
            local_image_path

        FROM products_raw

        WHERE
            status='downloaded'
    """)



    with engine.connect() as conn:

        products = conn.execute(
            query
        ).fetchall()



    print(
        "Products waiting for embedding:",
        len(products)
    )



    total = 0



    for product in products:


        try:


            print(
                "\nEmbedding:",
                product.title
            )



            with open(
                product.local_image_path,
                "rb"
            ) as image:


                embedding = generate_image_embedding(
                    image
                )



            print(
                "Embedding shape:",
                embedding.shape
            )



            # Convert torch tensor -> pgvector string

            vector = embedding_to_vector(
                embedding
            )



            update = text("""
                UPDATE products_raw

                SET

                    embedding = CAST(:embedding AS vector),

                    embedding_status='embedded',

                    status='embedded',

                    embedded_at=NOW()

                WHERE
                    id=:id
            """)



            with engine.begin() as conn:

                conn.execute(
                    update,
                    {
                        "embedding": vector,
                        "id": product.id
                    }
                )



            print(
                "Done:",
                product.title
            )


            total += 1



        except Exception as e:


            print(
                "Failed:",
                product.title,
                e
            )



    return total





if __name__ == "__main__":


    count = process_embeddings()


    print(
        "\nEmbedded:",
        count
    )