def normalize_score(value):

    if value is None:
        return 0


    value = float(value)


    # Convert percentage score
    if value > 1:

        return value / 100


    return value



def calculate_final_score(product):


    vector_score = normalize_score(
        product.get(
            "similarity",
            0
        )
    )


    metadata_score = normalize_score(
        product.get(
            "metadata_score",
            0
        )
    )


    text_score = normalize_score(
        product.get(
            "text_score",
            0
        )
    )


    popularity_score = normalize_score(
        product.get(
            "popularity_score",
            50
        )
    )



    # =============================
    # TEXT SEARCH
    # =============================

    if vector_score == 0:


        final = (

            metadata_score * 0.50

            +

            text_score * 0.30

            +

            popularity_score * 0.20

        )



    # =============================
    # IMAGE SEARCH
    # =============================

    else:


        final = (

            vector_score * 0.60

            +

            metadata_score * 0.25

            +

            popularity_score * 0.15

        )



    return round(
        final * 100,
        2
    )





def rank_final_products(products):


    for product in products:


        product["final_score"] = calculate_final_score(
            product
        )



    products.sort(

        key=lambda x:
        x.get(
            "final_score",
            0
        ),

        reverse=True

    )


    return products