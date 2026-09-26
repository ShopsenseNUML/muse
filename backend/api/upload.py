"""
Image upload endpoint for adding new products to the catalog.

TODO(Phase B): wire into the ingestion pipeline
(csv_import_worker / embedding_worker) so an uploaded image is
embedded and inserted into products_raw. The router is not mounted
in backend/main.py yet.
"""

from fastapi import (
    APIRouter,
    UploadFile,
    File,
    Form
)


router = APIRouter(
    prefix="/upload",
    tags=["Upload"]
)


@router.post("/image")
async def upload_image(
    file: UploadFile = File(...),
    title: str = Form(""),
    category: str = Form("")
):
    """
    Accept a product image for later indexing.

    Currently only acknowledges receipt. Phase B will route the
    saved image into the embedding pipeline.
    """

    return {
        "status": "received",
        "filename": file.filename,
        "content_type": file.content_type,
        "title": title,
        "category": category,
        "message": (
            "Upload received. Indexing pipeline integration "
            "is pending (Phase B)."
        )
    }
