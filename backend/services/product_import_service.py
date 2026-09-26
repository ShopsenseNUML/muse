import os
import uuid

from pathlib import Path

from sqlalchemy import text

from backend.db.database import engine


from backend.services.clip_service import (
    generate_image_embedding
)


from backend.services.vector_service import (
    check_duplicate_embedding
)


from backend.services.metadata_extraction_service import (
    extract_metadata
)





SUPPORTED_EXTENSIONS = [

    ".jpg",
    ".jpeg",
    ".png",
    ".webp"

]





def clean_title(filename):

    title = Path(
        filename
    ).stem


    title = title.replace(
        "_",
        " "
    )


    title = title.replace(
        "-",
        " "
    )


    return title.strip()





def import_product_folder(folder_path):


    imported = 0

    skipped = 0



    for filename in os.listdir(folder_path):


        ext = os.path.splitext(
            filename
        )[1].lower()



        if ext not in SUPPORTED_EXTENSIONS:

            continue




        image_path = os.path.join(
            folder_path,
            filename
        )



        print(
            "\nProcessing:",
            filename
        )



        try:



            # =================================
            # 1. Generate CLIP embedding
            # =================================


            with open(
                image_path,
                "rb"
            ) as image:


                embedding = generate_image_embedding(
                    image
                )





            print(
                "Embedding generated:",
                embedding.shape
            )





            # =================================
            # 2. Duplicate detection
            # =================================


            duplicate = check_duplicate_embedding(
                embedding
            )



            if duplicate["duplicate"]:


                print(
                    "Duplicate skipped:",
                    duplicate["title"],
                    duplicate["similarity"]
                )


                skipped += 1

                continue





            # =================================
            # 3. Metadata extraction
            # =================================


            title = clean_title(
                filename
            )


            metadata = extract_metadata(
                title
            )



            brand = metadata.get(
                "brand"
            )


            category = metadata.get(
                "category"
            )


            description = metadata.get(
                "description"
            )



            # fallback values

            brand = brand or "Unknown"

            category = category or "Unknown"

            description = description or title





            # =================================
            # 4. Convert vector
            # =================================


            vector = "[" + ",".join(

                map(
                    str,
                    embedding.tolist()
                )

            ) + "]"





            product_id = str(
                uuid.uuid4()
            )





            # =================================
            # 5. Insert product
            # =================================


            insert_query = text("""

                INSERT INTO products
                (

                    id,

                    title,

                    description,

                    price,

                    platform,

                    image_url,

                    category,

                    embedding,

                    created_at,

                    brand,

                    source_url,

                    original_image_url,

                    local_image_path

                )


                VALUES

                (

                    :id,

                    :title,

                    :description,

                    :price,

                    :platform,

                    :image_url,

                    :category,

                    CAST(:embedding AS vector),

                    NOW(),

                    :brand,

                    :source_url,

                    :original_image_url,

                    :local_image_path

                )

            """)





            with engine.begin() as conn:


                conn.execute(

                    insert_query,

                    {


                        "id":
                        product_id,


                        "title":
                        title,


                        "description":
                        description,


                        "price":
                        0,


                        "platform":
                        "local",


                        "image_url":
                        image_path,


                        "category":
                        category,


                        "embedding":
                        vector,


                        "brand":
                        brand,


                        "source_url":
                        None,


                        "original_image_url":
                        None,


                        "local_image_path":
                        image_path

                    }

                )





            imported += 1



            print(
                "Inserted:",
                title,
                "|",
                brand,
                "|",
                category
            )





        except Exception as e:


            print(
                "FAILED:",
                filename,
                e
            )





    print("\n====================")

    print(
        "Imported:",
        imported
    )


    print(
        "Skipped:",
        skipped
    )


    print("====================")



    return imported