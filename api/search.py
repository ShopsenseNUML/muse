import time

from fastapi import (
    APIRouter,
    UploadFile,
    File
)

from backend.services.clip_service import (
    generate_image_embedding
)

from backend.services.vector_service import (
    get_exact_match,
    get_candidate_products
)

from backend.services.ranking_service import (
    enrich_metadata_scores,
    rank_products
)

from backend.services.search_logger import (
    log_search
)


router = APIRouter()


@router.post("/image")
async def search_image(
    file: UploadFile = File(...)
):

    start_time = time.time()

    # -----------------------------
    # Generate CLIP Embedding
    # -----------------------------

    embedding = generate_image_embedding(
        file.file
    )

    embedding_dimension = (
        embedding.shape[-1]
    )

    # -----------------------------
    # Exact Match
    # -----------------------------

    exact = get_exact_match(
        embedding,
        threshold=0.90
    )

    if exact:

        results = [
            {
                **exact,
                "match_type": "Exact",
                "final_score": exact["similarity"]
            }
        ]

    else:

        # -----------------------------
        # Candidate Retrieval
        # -----------------------------

        results = get_candidate_products(
            embedding,
            limit=50
        )

        # -----------------------------
        # Metadata Ranking
        # -----------------------------

        results = enrich_metadata_scores(
            results
        )

        results = rank_products(
            results
        )

        results = results[:10]

        # -----------------------------
        # Labels
        # -----------------------------

        for item in results:

            score = float(
                item.get(
                    "final_score",
                    0
                )
            )

            if score >= 0.85:

                item["match_type"] = (
                    "Very Similar"
                )

            elif score >= 0.70:

                item["match_type"] = (
                    "Related"
                )

            else:

                item["match_type"] = (
                    "Weak"
                )

    # -----------------------------
    # Analytics
    # -----------------------------

    latency = (
        time.time()
        -
        start_time
    )

    log_search(
        latency,
        len(results)
    )

    return {

        "query": {

            "embedding_dimension":
            embedding_dimension,

            "processing_time":
            round(
                latency,
                4
            )

        },

        "count":
        len(results),

        "results":
        results

    }