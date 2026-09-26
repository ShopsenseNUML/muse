def calculate_brand_score(
    product_brand,
    query_brand
):

    if not query_brand:
        return 0


    if not product_brand:
        return 0


    if product_brand.lower() == query_brand.lower():

        return 40


    return 0



def calculate_category_score(
    product_category,
    query_category
):

    if not query_category:
        return 0


    if not product_category:
        return 0


    if product_category.lower() == query_category.lower():

        return 30


    return 0




def calculate_price_score(
    price,
    max_price
):

    if not max_price:
        return 0


    if not price:
        return 0



    if price <= max_price:

        # cheaper gets better score

        difference = (
            max_price - price
        ) / max_price


        return min(
            20,
            difference * 20
        )


    return -20





def calculate_keyword_score(
    product,
    keywords
):


    if not keywords:

        return 0



    text = " ".join([

        str(product.get("title","")),

        str(product.get("description","")),

        str(product.get("brand",""))

    ]).lower()



    matches = 0


    for word in keywords:


        if word.lower() in text:

            matches += 1



    return min(
        10,
        matches * 3
    )





def calculate_metadata_score(
    product,
    analysis
):


    score = 0



    score += calculate_brand_score(

        product.get("brand"),

        analysis.get("brand")

    )



    score += calculate_category_score(

        product.get("category"),

        analysis.get("category")

    )



    score += calculate_price_score(

        product.get("price"),

        analysis.get("max_price")

    )



    score += calculate_keyword_score(

        product,

        analysis.get("keywords")

    )



    return round(
        score,
        2
    )