import re



def normalize_text(text):

    if not text:
        return ""

    return text.lower()



def calculate_text_score(
    product,
    analysis
):


    score = 0



    title = normalize_text(
        product.get("title")
    )


    brand = normalize_text(
        product.get("brand")
    )


    category = normalize_text(
        product.get("category")
    )


    description = normalize_text(
        product.get("description")
    )



    keywords = analysis.get(
        "keywords",
        []
    )



    # -------------------------
    # Keyword matching
    # -------------------------

    for keyword in keywords:


        keyword = keyword.lower()


        if keyword in title:

            score += 25


        elif keyword in description:

            score += 10



    # -------------------------
    # Brand matching
    # -------------------------

    query_brand = analysis.get(
        "brand"
    )


    if query_brand:


        if query_brand.lower() == brand:

            score += 30



    # -------------------------
    # Category matching
    # -------------------------

    query_category = analysis.get(
        "category"
    )


    if query_category:


        if query_category.lower() == category:

            score += 20



    # -------------------------
    # Normalize
    # -------------------------

    if score > 100:

        score = 100



    return score