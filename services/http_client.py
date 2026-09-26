"""
Shared HTTP client with retry + exponential backoff.

Pattern inspired by robust web-tooling practice (e.g. self-hosted AI
workspaces that must tolerate flaky upstream sites): every outbound
request is retried with exponential backoff and jitter, and only
raises after all attempts are exhausted.

All ShopSense scrapers and providers should go through `http_get` /
`http_post` instead of calling requests directly, so rate-limiting
and transient network errors are handled uniformly.
"""

import logging
import random
import time

from typing import Optional, Dict, Any

import requests


logger = logging.getLogger(__name__)


# ----------------------------------------------------------
# Defaults
# ----------------------------------------------------------

DEFAULT_TIMEOUT = 15
DEFAULT_MAX_RETRIES = 3
DEFAULT_BACKOFF_BASE = 1.0  # seconds; doubled each retry
DEFAULT_BACKOFF_MAX = 30.0  # cap a single backoff sleep

# Retry on these status codes (rate-limiting, transient server errors).
RETRY_STATUS = {429, 500, 502, 503, 504}

# Retry on these exceptions (network blips, DNS hiccups).
RETRY_EXCEPTIONS = (
    requests.exceptions.Timeout,
    requests.exceptions.ConnectionError,
    requests.exceptions.ChunkedEncodingError
)


def _backoff_sleep(attempt: int, base: float, cap: float) -> None:
    """
    Exponential backoff with full jitter:
        delay = uniform(0, base * 2^attempt), capped at `cap`.
    Jitter spreads concurrent retries so we don't hammer a recovering
    server in lockstep.
    """

    raw = min(cap, base * (2 ** attempt))

    delay = random.uniform(0, raw)

    logger.debug(
        "backoff attempt=%d sleeping %.2fs (raw=%.2fs)",
        attempt, delay, raw
    )

    time.sleep(delay)


def _do_request(
    method: str,
    url: str,
    *,
    headers: Optional[Dict[str, str]] = None,
    params: Optional[Dict[str, Any]] = None,
    json_body: Optional[Any] = None,
    data: Optional[Any] = None,
    cookies: Optional[Dict[str, str]] = None,
    timeout: int = DEFAULT_TIMEOUT,
    max_retries: int = DEFAULT_MAX_RETRIES,
    backoff_base: float = DEFAULT_BACKOFF_BASE,
    backoff_max: float = DEFAULT_BACKOFF_MAX
) -> requests.Response:
    """
    Perform an HTTP request with retry/backoff. Raises only after all
    retries are exhausted.
    """

    last_exc: Optional[Exception] = None

    last_resp: Optional[requests.Response] = None

    for attempt in range(max_retries + 1):

        try:

            resp = requests.request(
                method,
                url,
                headers=headers,
                params=params,
                json=json_body,
                data=data,
                cookies=cookies,
                timeout=timeout
            )

            # Retry on transient status codes
            if resp.status_code in RETRY_STATUS:

                last_resp = resp

                if attempt < max_retries:

                    logger.debug(
                        "%s %s -> %d, retrying (attempt %d/%d)",
                        method, url, resp.status_code,
                        attempt + 1, max_retries
                    )

                    _backoff_sleep(attempt, backoff_base, backoff_max)

                    continue

                return resp  # exhausted; return the error response

            return resp

        except RETRY_EXCEPTIONS as e:

            last_exc = e

            if attempt < max_retries:

                logger.debug(
                    "%s %s raised %s, retrying (attempt %d/%d)",
                    method, url, type(e).__name__,
                    attempt + 1, max_retries
                )

                _backoff_sleep(attempt, backoff_base, backoff_max)

                continue

            raise  # exhausted; propagate the last network error

    # Should not reach here, but be defensive
    if last_resp is not None:

        return last_resp

    raise last_exc  # type: ignore[misc]


# ----------------------------------------------------------
# Public helpers
# ----------------------------------------------------------

def http_get(url: str, **kwargs) -> requests.Response:

    return _do_request("GET", url, **kwargs)


def http_post(url: str, **kwargs) -> requests.Response:

    return _do_request("POST", url, **kwargs)
