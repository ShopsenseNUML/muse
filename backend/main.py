from fastapi import FastAPI

from backend.api.admin import router as admin_router
from backend.api.search import router as search_router
from backend.api.text_search import (
    router as text_router
)
from backend.api.hybrid_search import (
    router as hybrid_router
)
from backend.api.products import (
    router as products_router
)
from backend.api.upload import (
    router as upload_router
)
from backend.api.comparison import (
    router as comparison_router
)


app = FastAPI(
    title="ShopSense API",
    description=(
        "AI visual search for Pakistani e-commerce. "
        "Supports image, text, and hybrid search with "
        "Roman Urdu query support and cross-platform "
        "price comparison."
    ),
    version="0.1.0"
)


# -------------------------
# Health & root
# -------------------------

@app.get("/")
def root():

    return {
        "message": "ShopSense API is running!"
    }


@app.get("/health")
def health():

    return {
        "status": "ok",
        "version": "0.0.1"
    }


# -------------------------
# Routers
# -------------------------

app.include_router(
    admin_router
)

app.include_router(
    hybrid_router,
    prefix="/search",
    tags=["Hybrid Search"]
)

app.include_router(
    text_router,
    prefix="/search"
)

app.include_router(
    search_router,
    prefix="/search",
    tags=["Search"]
)

app.include_router(
    products_router,
    tags=["Products"]
)

app.include_router(
    upload_router,
    tags=["Upload"]
)

app.include_router(
    comparison_router,
    tags=["Price Comparison"]
)
