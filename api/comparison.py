"""
Price-comparison endpoints.

Satisfies PDF objective #2: side-by-side price display from Daraz and
at least one other Pakistani store.

Two modes:
    POST /search/comparison/text   -> compare prices for a text query
    POST /search/comparison/image  -> embed image, find best local
                                      match, compare prices by its title

Roman Urdu queries are translated first via query_intelligence_service,
so "sasta smart watch" works too.
"""

import time

from fastapi import (
    APIRouter,
    UploadFile,
    File,
    Form
)
from pydantic import BaseModel

from backend.services.clip_service import (
    generate_image_embedding
)
from backend.services.comparison_service import (
    compare_prices
)
from backend.services.query_intelligence_service import (
    analyze_query
)
from backend.services.vector_service import (
    get_exact_match,
    get_candidate_products
)


router = APIRouter(
    tags=["Price Comparison"]
)


# ----------------------------------------------------------
# Text comparison
# ----------------------------------------------------------

class ComparisonRequest(BaseModel):

    query: str


@router.post("/search/comparison/text")
def compare_text(request: ComparisonRequest):

    start = time.time()

    # Translate Roman Urdu -> English and extract intelligence
    analysis = analyze_query(request.query)

    english_query = analysis["translated_query"]

    comparison = compare_prices(english_query)

    latency = time.time() - start

    return {
        "query": request.query,
        "translated_query": english_query,
        "was_translated": analysis["translation"]["was_translated"],
        "processing_time": round(latency, 4),
        "comparison": comparison
    }


# ----------------------------------------------------------
# Image comparison
# ----------------------------------------------------------

@router.post("/search/comparison/image")
async def compare_image(file: UploadFile = File(...)):

    """
    Embed the uploaded image, find the best local catalog match, then
    compare prices for that product's title across Daraz/Telemart.
    """

    start = time.time()

    embedding = generate_image_embedding(file.file)

    # Find the best local match (exact first, else top candidate)
    best = get_exact_match(embedding, threshold=0.70)

    if not best:

        candidates = get_candidate_products(embedding, limit=1)

        best = candidates[0] if candidates else None

    if not best:

        return {
            "error": "No matching product found in catalog",
            "processing_time": round(time.time() - start, 4)
        }

    # Use the matched product's title as the comparison query
    query = best.get("title") or ""

    comparison = compare_prices(query)

    latency = time.time() - start

    return {
        "matched_product": {
            "title": best.get("title"),
            "brand": best.get("brand"),
            "category": best.get("category"),
            "price": best.get("price"),
            "similarity": best.get("similarity") or best.get("clip_score"),
            "platform": best.get("platform")
        },
        "comparison": comparison,
        "processing_time": round(latency, 4)
    }
