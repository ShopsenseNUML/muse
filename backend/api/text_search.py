from fastapi import APIRouter, HTTPException

from pydantic import BaseModel

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

    results = search_by_metadata(
        analysis
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