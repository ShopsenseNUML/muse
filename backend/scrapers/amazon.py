"""
Amazon product scraper (catalog seeding only).

Uses Playwright to render Amazon search-result pages and extract
product cards. This is used to SEED the ShopSense catalog toward
the 5,000-10,000 product target from the PDF. Amazon is NOT used
as a live price-comparison source (it is not a Pakistani platform).

Original script credited to the project author; refactored here to:
  - run as an importable async function (no top-level await)
  - return normalized dicts instead of writing CSV
  - expose config (max_products, headless) as parameters
  - tolerate per-product failures without aborting the whole run

Note: Amazon actively blocks automation. If selectors change or
CAPTCHAs appear, this will need updating. For a more reliable
catalog source prefer the Daraz/Telemart scrapers.
"""

import asyncio
import random
import uuid
from typing import Dict, List, Optional

from playwright.async_api import (
    async_playwright,
    TimeoutError as PlaywrightTimeoutError
)


AMAZON_BASE = "https://www.amazon.com"
DEFAULT_QUERY_URL = "https://www.amazon.com/s?k={query}"


# ----------------------------------------------------------
# Single-card extraction
# ----------------------------------------------------------

async def _extract_card(product_card, context) -> Dict:
    """
    Extract one product from a search-result card, then visit the
    product page for its main image. Tolerates missing fields.
    """

    title = "Untitled"
    product_url = ""
    price = 0.0
    main_image_url = ""

    # ---- Title + URL from the results page ----
    try:

        link = product_card.locator("h2 a").first

        title = (await link.inner_text()).strip() or "Untitled"

        href = await link.get_attribute("href") or ""

        if href and not href.startswith("http"):

            href = AMAZON_BASE + href

        product_url = href

    except Exception:

        # Fallback selectors for variant layouts
        for selector in [
            "h2 span",
            "span.a-size-medium",
            "span.a-size-base-plus",
            "span.a-text-normal"
        ]:

            try:

                text = await product_card.locator(
                    selector
                ).first.inner_text()

                if text.strip():

                    title = text.strip()

                    break

            except Exception:

                pass

    # ---- Price ----
    try:

        price_text = await product_card.locator(
            ".a-price .a-offscreen"
        ).first.inner_text()

        # Strip currency symbols and commas: "$1,299.00" -> 1299.00
        cleaned = "".join(
            ch for ch in price_text
            if ch.isdigit() or ch == "."
        )

        price = float(cleaned) if cleaned else 0.0

    except Exception:

        price = 0.0

    # ---- Main image: prefer the card thumbnail (faster, no navigation) ----
    try:

        main_image_url = await product_card.locator(
            "img.s-image"
        ).first.get_attribute("src") or ""

    except Exception:

        main_image_url = ""

    # ---- Optionally visit product page for a higher-res image ----
    # Skipped by default to keep runs fast and avoid extra blocking.
    # Enable via visit_product_page=True if you need gallery images.

    return _normalize(
        title=title,
        price=price,
        image_url=main_image_url,
        product_url=product_url
    )


def _normalize(
    title: str,
    price: float,
    image_url: str,
    product_url: str
) -> Dict:
    """
    Normalize an Amazon product into the products_raw shape.
    Amazon has no brand/category on the card, so we leave them
    generic for the metadata-extraction step to fill in.
    """

    return {
        "id": str(uuid.uuid4()),
        "title": title,
        "brand": "Unknown",
        "category": "Unknown",
        "description": title,
        "price": price,
        "platform": "Amazon",
        "source_url": product_url,
        "image_url": image_url
    }


# ----------------------------------------------------------
# Full scrape
# ----------------------------------------------------------

async def scrape_amazon(
    query: str,
    max_products: int = 20,
    headless: bool = True,
    visit_product_page: bool = False,
    verbose: bool = True
) -> List[Dict]:
    """
    Scrape up to `max_products` Amazon results for `query`.
    Returns normalized product dicts ready for products_raw.
    """

    products: List[Dict] = []

    url = DEFAULT_QUERY_URL.format(query=query)

    async with async_playwright() as p:

        browser = await p.chromium.launch(headless=headless)

        context = await browser.new_context(
            viewport={"width": 1280, "height": 800},
            locale="en-US"
        )

        page = await context.new_page()

        try:

            await page.goto(
                url,
                wait_until="domcontentloaded",
                timeout=60000
            )

            await asyncio.sleep(
                random.uniform(2, 5)
            )

            await page.wait_for_selector(
                "div[data-component-type='s-search-result']",
                timeout=30000
            )

        except PlaywrightTimeoutError:

            if verbose:

                print(
                    "[amazon] timeout loading search results "
                    "(possibly a CAPTCHA). Aborting."
                )

            await browser.close()

            return products

        locator = page.locator(
            "div[data-component-type='s-search-result']"
        )

        count = await locator.count()

        if verbose:

            print(
                f"[amazon] query={query!r} "
                f"cards={count} taking={min(count, max_products)}"
            )

        for i in range(min(count, max_products)):

            if verbose:

                print(f"[amazon] card {i + 1}")

            try:

                card = locator.nth(i)

                product = await _extract_card(card, context)

                if visit_product_page and product["source_url"]:

                    await _enrich_from_product_page(
                        product,
                        context,
                        verbose=verbose
                    )

                products.append(product)

                # Polite delay between cards
                await asyncio.sleep(
                    random.uniform(0.5, 1.5)
                )

            except Exception as e:

                if verbose:

                    print(
                        f"[amazon] card {i + 1} failed: {e}"
                    )

                continue

        await browser.close()

    if verbose:

        print(
            f"[amazon] done: {len(products)} products"
        )

    return products


async def _enrich_from_product_page(
    product: Dict,
    context,
    verbose: bool = False
) -> None:
    """
    Open the product detail page and grab a higher-resolution main image.
    Optional; off by default for speed.
    """

    product_page = None

    try:

        product_page = await context.new_page()

        await product_page.goto(
            product["source_url"],
            wait_until="domcontentloaded",
            timeout=60000
        )

        await asyncio.sleep(random.uniform(2, 4))

        for selector in [
            "#landingImage",
            "img.a-dynamic-image.a-stretch-content"
        ]:

            try:

                el = product_page.locator(selector).first

                if await el.is_visible():

                    src = await el.get_attribute("src")

                    if src:

                        product["image_url"] = src

                        break

            except Exception:

                continue

    except Exception as e:

        if verbose:

            print(
                f"[amazon] enrich failed for "
                f"{product['source_url']}: {e}"
            )

    finally:

        if product_page:

            await product_page.close()


# ----------------------------------------------------------
# Sync wrapper (for use from non-async code / workers)
# ----------------------------------------------------------

def scrape_amazon_sync(
    query: str,
    max_products: int = 20,
    headless: bool = True,
    verbose: bool = True
) -> List[Dict]:
    """
    Synchronous entry point. Runs the async scraper in a fresh
    event loop. Use this from workers / CLI.
    """

    return asyncio.run(
        scrape_amazon(
            query=query,
            max_products=max_products,
            headless=headless,
            verbose=verbose
        )
    )
