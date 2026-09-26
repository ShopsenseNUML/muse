from fastapi import APIRouter

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

def text_search(
    request: SearchRequest
):

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