def rerank_products(products):

    for item in products:

        score = item["similarity"]

        category = (
            item.get("category")
            or ""
        ).lower()

        title = (
            item.get("title")
            or ""
        ).lower()

        # simple boosting

        if "watch" in category:
            score += 0.03

        if "watch" in title:
            score += 0.02

        item["rerank_score"] = score

    products.sort(
        key=lambda x: x["rerank_score"],
        reverse=True
    )

    return products