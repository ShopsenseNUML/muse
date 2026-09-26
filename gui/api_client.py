"""
Thin HTTP client for the ShopSense backend.

Wraps every FastAPI endpoint so the GUI (and any other client) can
call them without dealing with requests plumbing. Pure stdlib + requests,
no Tkinter dependency, so it is reusable and unit-testable on its own.

All methods return parsed JSON (dict/list) and raise ShopSenseAPIError
on non-2xx responses or connection failures.
"""

from typing import Optional, Dict, Any, List, Tuple
from pathlib import Path

import requests


class ShopSenseAPIError(Exception):
    """Raised when the backend returns an error or is unreachable."""

    pass


class ShopSenseClient:

    def __init__(self, base_url: str = "http://127.0.0.1:8000", timeout: int = 30):

        self.base_url = base_url.rstrip("/")
        self.timeout = timeout

    # ----------------------------------------------------------
    # Internal
    # ----------------------------------------------------------

    def _url(self, path: str) -> str:

        if not path.startswith("/"):

            path = "/" + path

        return self.base_url + path

    def _check(self, response: requests.Response) -> Dict[str, Any]:

        if not response.ok:

            raise ShopSenseAPIError(
                f"HTTP {response.status_code}: {response.text[:300]}"
            )

        return response.json()

    # ----------------------------------------------------------
    # Health / system
    # ----------------------------------------------------------

    def root(self) -> Dict[str, Any]:

        return self._check(
            requests.get(self._url("/"), timeout=self.timeout)
        )

    def health(self) -> Dict[str, Any]:

        return self._check(
            requests.get(self._url("/health"), timeout=self.timeout)
        )

    # ----------------------------------------------------------
    # Search
    # ----------------------------------------------------------

    def search_image(self, image_path: str) -> Dict[str, Any]:
        """
        POST /search/image  — visual search by product photo.
        """

        with open(image_path, "rb") as f:

            files = {"file": (Path(image_path).name, f)}

            return self._check(
                requests.post(
                    self._url("/search/image"),
                    files=files,
                    timeout=self.timeout
                )
            )

    def search_text(self, query: str) -> Dict[str, Any]:
        """
        POST /search/text  — text search (Roman Urdu auto-translated).
        """

        return self._check(
            requests.post(
                self._url("/search/text"),
                json={"query": query},
                timeout=self.timeout
            )
        )

    def search_hybrid(
        self,
        image_path: str,
        query: str = ""
    ) -> Dict[str, Any]:
        """
        POST /search/hybrid  — image + text combined search.
        """

        with open(image_path, "rb") as f:

            files = {"file": (Path(image_path).name, f)}

            data = {"query": query}

            return self._check(
                requests.post(
                    self._url("/search/hybrid"),
                    files=files,
                    data=data,
                    timeout=self.timeout
                )
            )

    # ----------------------------------------------------------
    # Price comparison
    # ----------------------------------------------------------

    def compare_text(self, query: str) -> Dict[str, Any]:
        """
        POST /search/comparison/text  — side-by-side prices by query.
        """

        return self._check(
            requests.post(
                self._url("/search/comparison/text"),
                json={"query": query},
                timeout=self.timeout
            )
        )

    def compare_image(self, image_path: str) -> Dict[str, Any]:
        """
        POST /search/comparison/image  — match a photo then compare prices.
        """

        with open(image_path, "rb") as f:

            files = {"file": (Path(image_path).name, f)}

            return self._check(
                requests.post(
                    self._url("/search/comparison/image"),
                    files=files,
                    timeout=self.timeout
                )
            )

    # ----------------------------------------------------------
    # Catalog
    # ----------------------------------------------------------

    def list_products(self, limit: int = 20) -> Dict[str, Any]:
        """
        GET /products/  — browse catalog.
        """

        return self._check(
            requests.get(
                self._url("/products/"),
                params={"limit": limit},
                timeout=self.timeout
            )
        )

    def get_product(self, product_id: str) -> Dict[str, Any]:
        """
        GET /products/{id}  — single product.
        """

        return self._check(
            requests.get(
                self._url(f"/products/{product_id}"),
                timeout=self.timeout
            )
        )

    # ----------------------------------------------------------
    # Admin
    # ----------------------------------------------------------

    def catalog_stats(self) -> Dict[str, Any]:

        return self._check(
            requests.get(
                self._url("/admin/catalog/stats"),
                timeout=self.timeout
            )
        )

    def dictionary_stats(self) -> Dict[str, Any]:

        return self._check(
            requests.get(
                self._url("/admin/dictionary/stats"),
                timeout=self.timeout
            )
        )

    def pipeline_stats(self) -> Dict[str, Any]:

        return self._check(
            requests.get(
                self._url("/admin/pipeline/stats"),
                timeout=self.timeout
            )
        )
