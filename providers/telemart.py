"""
Telemart (telemart.pk) price-aggregation provider.

Satisfies PDF objective #2: cross-platform price comparison with a
local Pakistani platform. Telemart is used as the second source
(alongside Daraz) for side-by-side price display.

Approach: Telemart's frontend uses Algolia for search. We reuse the
already-tested `search_telemart_live` function from the scrapers
module (which routes through the shared retry/backoff HTTP client) and
cache results in Redis for 6 hours per the PDF methodology.
"""

import logging
from typing import List, Optional, Dict

from backend.providers.base import (
    BaseProvider,
    ProductResult
)
from backend.scrapers.telemart import search_telemart_live
from backend.services.cache_service import (
    cache_get_json,
    cache_set_json
)


logger = logging.getLogger(__name__)


CACHE_TTL = 6 * 60 * 60  # 6 hours


class TelemartProvider(BaseProvider):

    name = "telemart"

    def __init__(self, timeout: float = 15.0):

        super().__init__(timeout=timeout)

    # ----------------------------------------------------------
    # Public API
    # ----------------------------------------------------------

    def search(
        self,
        query: str,
        limit: int = 10
    ) -> List[ProductResult]:
        """
        Search Telemart for `query`, returning up to `limit` results.
        Cached for CACHE_TTL seconds.
        """

        cache_key = f"telemart:search:{query.lower().strip()}:{limit}"

        cached = cache_get_json(cache_key)

        if cached is not None:

            return [
                ProductResult(**item)
                for item in cached
            ]

        try:

            hits = search_telemart_live(query, limit=limit)

            results = [
                ProductResult(
                    product_id=h["product_id"],
                    title=h["title"],
                    price=h["price"],
                    currency=h.get("currency", "PKR"),
                    url=h.get("url", ""),
                    image_url=h.get("image_url", ""),
                    in_stock=h.get("in_stock", True),
                    extra={}
                )
                for h in hits
            ]

            cache_set_json(
                cache_key,
                [r.to_dict() for r in results],
                ttl=CACHE_TTL
            )

            return results

        except Exception as e:

            logger.warning(
                "TelemartProvider.search(%r) failed: %s",
                query, e
            )

            return []

    def get_price(
        self,
        product_id: str
    ) -> Optional[float]:
        """
        Direct price-by-id is not exposed cleanly; use
        get_cheapest_price(query) instead.
        """

        return None

    def get_cheapest_price(
        self,
        query: str
    ) -> Optional[Dict]:
        """
        Return the cheapest current Telemart price for a query:
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

            return len(search_telemart_live("watch", limit=1)) > 0

        except Exception:

            return False
