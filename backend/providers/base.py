"""
Search / price provider interface.

Each provider wraps a single e-commerce source (Daraz, a Shopify
store, etc.) and exposes a uniform interface so the rest of the
system can query products and prices without knowing the source.

Concrete providers (DarazProvider, ShopifyProvider) are implemented
in Phase B.
"""

from abc import ABC, abstractmethod
from typing import List, Optional, Dict


class ProductResult:
    """
    Lightweight product record returned by a provider.
    Deliberately simple so providers don't depend on the DB models.
    """

    def __init__(
        self,
        product_id: str,
        title: str,
        price: float,
        currency: str = "PKR",
        url: str = "",
        image_url: str = "",
        in_stock: bool = True,
        extra: Optional[Dict] = None
    ):

        self.product_id = product_id
        self.title = title
        self.price = price
        self.currency = currency
        self.url = url
        self.image_url = image_url
        self.in_stock = in_stock
        self.extra = extra or {}

    def to_dict(self):

        return {
            "product_id": self.product_id,
            "title": self.title,
            "price": self.price,
            "currency": self.currency,
            "url": self.url,
            "image_url": self.image_url,
            "in_stock": self.in_stock,
            "extra": self.extra
        }


class BaseProvider(ABC):
    """
    Abstract base for all e-commerce providers.
    """

    name: str = "base"

    def __init__(self, timeout: float = 5.0):

        self.timeout = timeout

    @abstractmethod
    def search(
        self,
        query: str,
        limit: int = 10
    ) -> List[ProductResult]:
        """
        Search the provider's catalog for `query`.
        """
        raise NotImplementedError

    @abstractmethod
    def get_price(
        self,
        product_id: str
    ) -> Optional[float]:
        """
        Return the current price for a product id, or None.
        """
        raise NotImplementedError

    def health_check(self) -> bool:
        """
        Override to implement an actual reachability check.
        Default returns True.
        """
        return True
