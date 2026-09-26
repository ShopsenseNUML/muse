def calculate_final_score(product):

    clip_score = float(
        product.get(
            "clip_score",
            0
        )
    )

    category_score = float(
        product.get(
            "category_score",
            0
        )
    )

    brand_score = float(
        product.get(
            "brand_score",
            0
        )
    )

    price_score = float(
        product.get(
            "price_score",
            0
        )
    )

    final_score = (

        clip_score * 0.70

        +

        category_score * 0.15

        +

        brand_score * 0.10

        +

        price_score * 0.05

    )

    return round(
        final_score,
        6
    )


def enrich_metadata_scores(
    products
):

    if not products:
        return []

    reference = products[0]

    reference_category = (
        reference.get(
            "category"
        )
    )

    reference_brand = (
        reference.get(
            "brand"
        )
    )

    reference_price = (
        reference.get(
            "price",
            0
        )
    )

    for product in products:

        product["category_score"] = (
            1
            if product.get(
                "category"
            ) == reference_category
            else 0
        )

        product["brand_score"] = (
            1
            if product.get(
                "brand"
            ) == reference_brand
            else 0
        )

        price = product.get(
            "price",
            0
        )

        if (
            reference_price
            and
            price
        ):

            diff = abs(
                price -
                reference_price
            )

            product[
                "price_score"
            ] = max(
                0,
                1 -
                (
                    diff /
                    max(
                        reference_price,
                        1
                    )
                )
            )

        else:

            product[
                "price_score"
            ] = 0

    return products


def rank_products(
    products
):

    for product in products:

        product[
            "final_score"
        ] = calculate_final_score(
            product
        )

    products.sort(
        key=lambda x:
        x["final_score"],
        reverse=True
    )

    return products