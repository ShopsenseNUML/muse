"""
Redis cache helper for ShopSense.

A thin wrapper around redis-py that degrades gracefully: if Redis is
unavailable, every call becomes a no-op so the search service still
works (just slower). This matches the "graceful degradation" design
principle from the architecture notes.

Used by the price-comparison providers to cache live price lookups
for 6-12 hours per the PDF methodology (section 5.2 Step 4).
"""

import json
import logging

from typing import Optional, Any

import redis


logger = logging.getLogger(__name__)


# Default TTL for cached prices (6 hours in seconds).
DEFAULT_PRICE_TTL = 6 * 60 * 60


# ----------------------------------------------------------
# Connection (lazy singleton)
# ----------------------------------------------------------

_client = None
_unavailable = False


def _get_client():
    """
    Return a Redis client, or None if Redis is unavailable.
    Once a connection fails, we stop retrying for the process lifetime
    to avoid log spam on every request.
    """

    global _client, _unavailable

    if _unavailable:

        return None

    if _client is None:

        try:

            _client = redis.Redis(
                host="localhost",
                port=6379,
                decode_responses=True,
                socket_connect_timeout=1,
                socket_timeout=1
            )

            _client.ping()

        except Exception as e:

            logger.warning(
                "Redis unavailable, caching disabled: %s",
                e
            )

            _unavailable = True

            _client = None

    return _client


# ----------------------------------------------------------
# Public API
# ----------------------------------------------------------

def cache_get_json(key: str) -> Optional[Any]:
    """
    Get a JSON-serialized value, or None on miss / Redis down.
    """

    client = _get_client()

    if client is None:

        return None

    try:

        raw = client.get(key)

        if raw is None:

            return None

        return json.loads(raw)

    except Exception as e:

        logger.debug("cache_get_json(%s) failed: %s", key, e)

        return None


def cache_set_json(
    key: str,
    value: Any,
    ttl: int = DEFAULT_PRICE_TTL
) -> bool:
    """
    Set a JSON-serialized value with a TTL. No-op if Redis is down.
    """

    client = _get_client()

    if client is None:

        return False

    try:

        client.set(key, json.dumps(value, default=str), ex=ttl)

        return True

    except Exception as e:

        logger.debug("cache_set_json(%s) failed: %s", key, e)

        return False


def cache_delete(key: str) -> None:

    client = _get_client()

    if client is None:

        return

    try:

        client.delete(key)

    except Exception:

        pass


def is_available() -> bool:
    """True if Redis is connected and responding."""

    return _get_client() is not None
