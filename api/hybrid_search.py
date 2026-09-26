import time


from fastapi import (
    APIRouter,
    UploadFile,
    File,
    Form
)


from backend.services.clip_service import (
    generate_image_embedding
)


from backend.services.query_intelligence_service import (
    analyze_query
)


from backend.services.hybrid_search_service import (
    hybrid_search
)


from backend.services.search_logger import (
    log_search
)



router = APIRouter()



@router.post("/hybrid")
async def hybrid_search_api(

    file: UploadFile = File(...),

    query: str = Form("")

):


    start = time.time()



    # -------------------------
    # Image Embedding
    # -------------------------

    embedding = generate_image_embedding(
        file.file
    )



    # -------------------------
    # Text Intelligence
    # -------------------------

    analysis = analyze_query(
        query
    )



    # -------------------------
    # Hybrid Search
    # -------------------------

    results = hybrid_search(

        embedding,

        analysis

    )



    latency = time.time() - start



    log_search(
        latency,
        len(results)
    )



    return {


        "query": query,


        "analysis": analysis,


        "processing_time":
        round(
            latency,
            4
        ),


        "count":
        len(results),


        "results":
        results

    }