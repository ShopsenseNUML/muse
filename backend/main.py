from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

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
# CORS - the Flutter web app runs in a browser on a different
# origin/port, so the API must allow cross-origin requests.
# -------------------------

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


# -------------------------
# Seed product images — served by the API itself so the Flutter app can
# always resolve product image URLs (no separate static server needed).
# -------------------------

_SEED_IMAGE_DIR = Path(__file__).resolve().parent / "data" / "products"
if _SEED_IMAGE_DIR.is_dir():
    app.mount("/seed_images", StaticFiles(directory=_SEED_IMAGE_DIR), name="seed_images")


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
