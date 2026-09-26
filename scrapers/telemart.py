"""
Telemart product scraper.

Uses Telemart's public Algolia search endpoint to fetch product listings
for a query and normalize them into the ShopSense `products_raw` schema,
so the existing ingestion pipeline (download -> embed -> finalize) can
process them.

Also exposes `search_telemart_live()` for the TelemartProvider, which
returns the freshest price/title for a query without persisting.

Original script credited to the project author; refactored here to:
  - remove input() / display() (Jupyter-only constructs)
  - make cookies optional (not hardcoded secrets)
  - return normalized dicts instead of writing CSV
  - paginate safely with a max-page cap
"""

import time
from typing import Dict, List, Optional

from backend.services.http_client import http_post


# ----------------------------------------------------------
# Endpoint config
# ----------------------------------------------------------

ALGOLIA_URL = (
    "https://7z6unqyqer-dsn.algolia.net/1/indexes/*/queries"
)

DEFAULT_HEADERS = {
    "Content-Type": "application/json",
    "X-Algolia-API-Key": "9b4c33f99e845fe1363fd4c6ceb0f467",
    "X-Algolia-Application-Id": "7Z6UNQYQER",
    "User-Agent": "Mozilla/5.0"
}

# Cookies help avoid rate-limiting but are optional.
DEFAULT_COOKIES: Dict[str, str] = {}

# Safety cap so a popular query can't accidentally pull thousands of pages.
MAX_PAGES = 50
HITS_PER_PAGE = 20
PAGE_DELAY = 0.5  # seconds between pages, to be polite


# ----------------------------------------------------------
# Low-level search
# ----------------------------------------------------------

def search_telemart(
    query: str,
    page: int = 0,
    hits_per_page: int = HITS_PER_PAGE,
    cookies: Optional[Dict[str, str]] = None,
    timeout: int = 30
) -> Dict:
    """
    Query Telemart's Algolia index for one page of results.
    Returns the raw JSON response.
    """

    payload = {
        "requests": [
            {
                "indexName": "products",
                "params": (
                    f"query={query}"
                    f"&page={page}"
                    f"&hitsPerPage={hits_per_page}"
                )
            }
        ]
    }

    response = http_post(
        ALGOLIA_URL,
        json_body=payload,
        headers=DEFAULT_HEADERS,
        cookies=cookies or DEFAULT_COOKIES,
        timeout=timeout,
        max_retries=2
    )

    response.raise_for_status()

    return response.json()


# ----------------------------------------------------------
# Hit normalization
# ----------------------------------------------------------

def normalize_hit(item: Dict) -> Dict:
    """
    Convert one Algolia hit into the ShopSense products_raw shape.
    Only fields needed downstream are kept; everything else is dropped.
    """

    title = item.get("title") or ""
    slug = item.get("slug") or ""

    # Category: nested under categories[0].lvl2 (may be missing)
    category = ""

    cats = item.get("categories") or []

    if cats and isinstance(cats, list):

        category = cats[0].get("lvl2", "") or ""

    # Clean category: Algolia returns paths like "Electronics > Watches > Smart"
    if category and ">" in category:

        category = category.split(">")[-1].strip()

    # Build a stable product id so re-scraping the same product
    # does not create duplicates (ON CONFLICT DO NOTHING in the importer).
    product_id = str(item.get("id") or slug or title)

    price = item.get("sale_price")

    if price is None:

        price = item.get("price") or 0

    try:

        price = float(price)

    except (TypeError, ValueError):

        price = 0.0

    image_url = item.get("mainImageLink") or ""

    product_url = (
        f"https://telemart.pk/product/{slug}"
        if slug else ""
    )

    return {
        "id": product_id,
        "title": title.strip() or "Untitled",
        "brand": (item.get("brand") or "Unknown").strip(),
        "category": category.strip() or "Unknown",
        "description": title,  # Algolia hit has no long description
        "price": price,
        "platform": "Telemart",
        "source_url": product_url,
        "image_url": image_url
    }


# ----------------------------------------------------------
# Full multi-page scrape
# ----------------------------------------------------------

def scrape_telemart(
    query: str,
    max_pages: int = MAX_PAGES,
    cookies: Optional[Dict[str, str]] = None,
    verbose: bool = True
) -> List[Dict]:
    """
    Scrape all pages for a query (up to max_pages) and return a list
    of normalized product dicts ready for products_raw insertion.
    """

    first = search_telemart(query, 0, cookies=cookies)

    result = first["results"][0]

    total_hits = result.get("nbHits", 0)

    total_pages = min(
        result.get("nbPages", 1),
        max_pages
    )

    if verbose:

        print(
            f"[telemart] query={query!r} "
            f"hits={total_hits} pages={total_pages}"
        )

    products: List[Dict] = []

    for page in range(total_pages):

        if verbose:

            print(
                f"[telemart] page {page + 1}/{total_pages}"
            )

        try:

            data = search_telemart(
                query,
                page,
                cookies=cookies
            )

            hits = data["results"][0].get("hits", [])

        except Exception as e:

            print(
                f"[telemart] page {page + 1} failed: {e}"
            )

            continue

        for hit in hits:

            products.append(
                normalize_hit(hit)
            )

        time.sleep(PAGE_DELAY)

    # Deduplicate by id (a product can appear across pages)
    seen = set()

    unique: List[Dict] = []

    for p in products:

        if p["id"] in seen:

            continue

        seen.add(p["id"])

        unique.append(p)

    if verbose:

        print(
            f"[telemart] done: {len(unique)} unique products"
        )

    return unique


# ----------------------------------------------------------
# Live lookup (for TelemartProvider)
# ----------------------------------------------------------

def search_telemart_live(
    query: str,
    limit: int = 10
) -> List[Dict]:
    """
    Return the freshest top-N products for a query WITHOUT persisting.
    Used by the price-comparison provider so prices reflect the live site.

    Each dict has: product_id, title, price, url, image_url, in_stock.
    """

    data = search_telemart(query, 0)

    hits = data["results"][0].get("hits", [])[:limit]

    out: List[Dict] = []

    for hit in hits:

        slug = hit.get("slug") or ""

        out.append({
            "product_id": str(hit.get("id") or slug),
            "title": hit.get("title") or "Untitled",
            "price": float(hit.get("sale_price") or hit.get("price") or 0),
            "currency": "PKR",
            "url": f"https://telemart.pk/product/{slug}" if slug else "",
            "image_url": hit.get("mainImageLink") or "",
            "in_stock": (hit.get("qty") or 0) > 0
        })

    return out
