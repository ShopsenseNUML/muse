from backend.services.vector_service import (
    get_candidate_products
)


from backend.services.metadata_ranker import (
    calculate_metadata_score
)


from backend.services.text_ranker import (
    calculate_text_score
)


from backend.services.unified_ranker import (
    rank_final_products
)




def hybrid_search(
    embedding,
    analysis,
    limit=50
):


    # ---------------------------------
    # 1. Vector Candidate Retrieval
    # ---------------------------------

    products = get_candidate_products(
        embedding,
        limit=limit
    )



    # ---------------------------------
    # 2. Add Intelligence Scores
    # ---------------------------------

    for product in products:


        product["metadata_score"] = (
            calculate_metadata_score(
                product,
                analysis
            )
        )



        product["text_score"] = (
            calculate_text_score(
                product,
                analysis
            )
        )



        # Temporary popularity

        product["popularity_score"] = 50



    # ---------------------------------
    # 3. Unified Ranking
    # ---------------------------------

    ranked = rank_final_products(
        products
    )



    return ranked[:10]