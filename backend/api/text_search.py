from fastapi import APIRouter, HTTPException

from pydantic import BaseModel
from sqlalchemy.exc import OperationalError, ProgrammingError

from backend.services.query_intelligence_service import (
    analyze_query
)

from backend.services.search_service import (
    search_by_metadata
)


router = APIRouter()


class SearchRequest(BaseModel):

    query: str


@router.post("/text")

def text_search(request: SearchRequest | list[SearchRequest]):
    # Accept {"query": "..."} — and tolerate [{"query": "..."}] (a
    # single-element list), which some clients/docs users send.
    if isinstance(request, list):
        if not request:
            raise HTTPException(
                status_code=422,
                detail='Request body must be {"query": "<search text>"}',
            )
        request = request[0]

    analysis = analyze_query(
        request.query
    )

    try:
        results = search_by_metadata(
            analysis
        )
    except (ProgrammingError, OperationalError):
        # e.g. the products table was never created on this machine
        raise HTTPException(
            status_code=503,
            detail=(
                "Product database is not initialized. Run: "
                "python -m backend.scripts.init_db && "
                "python -m backend.scripts.seed_sample_products"
            ),
        )

    return {

        "query":
        request.query,

        "analysis":
        analysis,

        "count":
        len(results),

        "results":
        results

    }