"""
Daraz (daraz.pk) price-aggregation provider.

Satisfies PDF objective #2: cross-platform price comparison with a
local Pakistani platform.

Approach: Daraz exposes a public search JSON endpoint that the web
frontend itself calls. We hit it directly (no browser) for speed and
cache results in Redis for 6 hours per the required methodology.

The provider implements both:
    - search(query)        -> list of ProductResult  (catalog/results)
    - get_price(query)     -> cheapest current price (comparison)

Note: Daraz can change its API without notice. The provider degrades
gracefully: any failure returns an empty list / None and logs, so the
comparison endpoint still works with Telemart alone.
"""

import logging
from typing import List, Optional, Dict
from urllib.parse import quote

from backend.providers.base import (
    BaseProvider,
    ProductResult
)
from backend.services.cache_service import (
    cache_get_json,
    cache_set_json
)
from backend.services.http_client import http_get


logger = logging.getLogger(__name__)


# Daraz public search endpoint. Returns JSON with a `mods.listItems` array.
DARAZ_SEARCH_URL = (
    "https://www.daraz.pk/catalog/?"
    "ajax=true"
    "&from=input"
    "&page={page}"
    "&q={query}"
    "&spm=a2a0e.searchcategory.search.go.35f97412Q8Z7rT"
)

DEFAULT_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/120.0 Safari/537.36"
    ),
    "Accept": "application/json, text/plain, */*",
    "Accept-Language": "en-US,en;q=0.9",
    "Referer": "https://www.daraz.pk/"
}

CACHE_TTL = 6 * 60 * 60  # 6 hours
TIMEOUT = 10


def _parse_price(value) -> Optional[float]:
    """Daraz returns prices as strings like '1,299.00'. Normalize."""

    if value is None:

        return None

    try:

        cleaned = "".join(
            ch for ch in str(value)
            if ch.isdigit() or ch == "."
        )

        return float(cleaned) if cleaned else None

    except (TypeError, ValueError):

        return None


class DarazProvider(BaseProvider):

    name = "daraz"

    def __init__(self, timeout: float = TIMEOUT):

        super().__init__(timeout=timeout)

    # ----------------------------------------------------------
    # Low-level fetch
    # ----------------------------------------------------------

    def _fetch_page(self, query: str, page: int = 1) -> Dict:
        """
        Fetch one page of Daraz search results as JSON.
        Raises on HTTP / parse errors.
        """

        url = DARAZ_SEARCH_URL.format(
            query=quote(query),
            page=page
        )

        response = http_get(
            url,
            headers=DEFAULT_HEADERS,
            timeout=int(self.timeout),
            max_retries=2
        )

        response.raise_for_status()

        # Daraz sometimes returns HTML on rate-limiting; guard against that
        try:

            return response.json()

        except ValueError as e:

            raise RuntimeError(
                f"Daraz returned non-JSON (likely rate-limited): {e}"
            )

    # ----------------------------------------------------------
    # Parse
    # ----------------------------------------------------------

    def _parse_items(self, data: Dict) -> List[ProductResult]:
        """
        Extract ProductResult list from a Daraz search response.
        Tolerates missing fields.
        """

        results: List[ProductResult] = []

        try:

            items = (
                data.get("mods", {})
                .get("listItems", [])
            )

        except AttributeError:

            items = []

        for item in items:

            product_id = str(item.get("nid") or item.get("itemId") or "")

            # Daraz uses 'name' for the full title; 'description' is an array.
            title = item.get("name") or "Untitled"

            price = _parse_price(item.get("price"))

            if price is None:

                price = _parse_price(item.get("priceShow")) or 0.0

            image = item.get("image") or ""

            if image and not image.startswith("http"):

                image = "https:" + image

            url = item.get("itemUrl") or ""

            if url and not url.startswith("http"):

                url = "https:" + url

            results.append(
                ProductResult(
                    product_id=product_id,
                    title=title,
                    price=price,
                    currency="PKR",
                    url=url,
                    image_url=image,
                    in_stock=(item.get("inStock", "1") != "0"),
                    extra={
                        "brand": item.get("brandName") or "",
                        "rating": item.get("ratingScore", ""),
                        "original_price": _parse_price(
                            item.get("originalPrice")
                        )
                    }
                )
            )

        return results

    # ----------------------------------------------------------
    # Public API
    # ----------------------------------------------------------

    def search(
        self,
        query: str,
        limit: int = 10
    ) -> List[ProductResult]:
        """
        Search Daraz for `query`, returning up to `limit` results.
        Results are cached for CACHE_TTL seconds.
        """

        cache_key = f"daraz:search:{query.lower().strip()}:{limit}"

        cached = cache_get_json(cache_key)

        if cached is not None:

            return [
                ProductResult(**item)
                for item in cached
            ]

        try:

            data = self._fetch_page(query, page=1)

            results = self._parse_items(data)[:limit]

            cache_set_json(
                cache_key,
                [r.to_dict() for r in results],
                ttl=CACHE_TTL
            )

            return results

        except Exception as e:

            logger.warning(
                "DarazProvider.search(%r) failed: %s",
                query, e
            )

            return []

    def get_price(
        self,
        product_id: str
    ) -> Optional[float]:
        """
        Daraz product ids from the ShopSense catalog are not stable
        across the live API, so price lookup is best done by query.
        Prefer `get_cheapest_price(query)`.
        """

        return None

    def get_cheapest_price(
        self,
        query: str
    ) -> Optional[Dict]:
        """
        Return the cheapest current Daraz price for a query:
            {price, currency, url, title, product_id, platform}
        or None if nothing found / on error.
        """

        results = self.search(query, limit=10)

        if not results:

            return None

        in_stock = [
            r for r in results
            if r.in_stock and r.price > 0
        ]

        if not in_stock:

            return None

        cheapest = min(in_stock, key=lambda r: r.price)

        return {
            "price": cheapest.price,
            "currency": cheapest.currency,
            "url": cheapest.url,
            "title": cheapest.title,
            "product_id": cheapest.product_id,
            "platform": self.name
        }

    def health_check(self) -> bool:

        try:

            data = self._fetch_page("watch", page=1)

            return "mods" in data

        except Exception:

            return False
