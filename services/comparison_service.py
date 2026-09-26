"""
Cross-platform price comparison service.

Satisfies PDF objective #2: aggregate and display product prices from
Daraz and at least one other Pakistani store in a side-by-side format.

This service queries all registered providers in parallel (via threads,
since providers are synchronous) and returns the cheapest price from
each, plus a computed best-deal summary.

The provider list is centralized here so adding a new store later is a
one-line change (the "plugin/provider" pattern).
"""

import logging

from concurrent.futures import (
    ThreadPoolExecutor,
    as_completed
)
from typing import Dict, List, Optional

from backend.providers.daraz import DarazProvider
from backend.providers.telemart import TelemartProvider


logger = logging.getLogger(__name__)


# Words that should RANK results, not be sent to the search box.
# Provider search engines (especially Telemart/Algolia) return zero
# results when these appear as terms, so we strip them before querying
# and rely on price-sorting to honor them instead.
SEARCH_STOPWORDS = {
    "cheap", "cheapest", "expensive", "best", "good",
    "new", "old", "small", "large", "low", "high",
    "price", "cost", "buy", "sale", "offer", "deal"
}


def clean_query_for_search(query: str) -> str:
    """
    Remove qualifier/stop words from a query before sending it to a
    provider's search endpoint. Colors, brands, and product nouns are
    kept; vague modifiers like 'cheap' are dropped (we honor them via
    price-sorting instead).
    """

    tokens = [
        t for t in query.lower().split()
        if t not in SEARCH_STOPWORDS
    ]

    return " ".join(tokens).strip() or query


# ----------------------------------------------------------
# Provider registry
#
# Add new providers here (Shopify, etc.) and they automatically
# participate in comparisons.
# ----------------------------------------------------------

def get_providers():

    return [
        DarazProvider(),
        TelemartProvider()
    ]


# ----------------------------------------------------------
# Comparison
# ----------------------------------------------------------

def compare_prices(
    query: str,
    timeout_per_provider: float = 8.0
) -> Dict:
    """
    Query all providers for `query` and return a side-by-side price
    comparison.

    Returns:
        {
            "query": <translated query>,
            "best":  {platform, price, ...} | None,
            "prices": [ {platform, price, currency, url, title, product_id} | None, ... ],
            "spread": {min, max, savings, savings_percent} | None,
            "available_platforms": int
        }

    Each provider runs in its own thread so a slow/hung provider does
    not delay the others. Failures degrade gracefully: a failed provider
    contributes a None entry rather than failing the whole comparison.
    """

    providers = get_providers()

    results: Dict[str, Optional[Dict]] = {}

    # Strip qualifier words (cheap, best, ...) so provider search
    # engines return real products; we honor intent via price-sorting.
    search_query = clean_query_for_search(query)

    def _query(provider):

        try:

            return provider.name, provider.get_cheapest_price(search_query)

        except Exception as e:

            logger.warning(
                "Provider %s failed for %r: %s",
                provider.name, query, e
            )

            return provider.name, None

    with ThreadPoolExecutor(
        max_workers=len(providers)
    ) as executor:

        futures = [
            executor.submit(_query, p)
            for p in providers
        ]

        for future in as_completed(
            futures,
            timeout=timeout_per_provider + 2
        ):

            try:

                name, price_info = future.result(
                    timeout=timeout_per_provider
                )

                results[name] = price_info

            except Exception as e:

                logger.warning(
                    "Provider future failed: %s", e
                )

    # Ensure every registered provider has an entry (None if it failed)
    prices: List[Optional[Dict]] = []

    for provider in providers:

        prices.append(results.get(provider.name))

    # ---- Compute best deal ----
    valid = [p for p in prices if p and p.get("price")]

    best = min(valid, key=lambda p: p["price"]) if valid else None

    # ---- Compute spread ----
    spread = None

    if len(valid) >= 2:

        min_price = min(p["price"] for p in valid)

        max_price = max(p["price"] for p in valid)

        savings = max_price - min_price

        spread = {
            "min": min_price,
            "max": max_price,
            "savings": round(savings, 2),
            "savings_percent": round(
                (savings / max_price) * 100, 1
            ) if max_price else 0
        }

    return {
        "query": query,
        "best": best,
        "prices": prices,
        "spread": spread,
        "available_platforms": len(valid)
    }
