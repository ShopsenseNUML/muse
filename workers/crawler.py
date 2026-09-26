"""
ShopSense catalog crawler.

Drives the Telemart and Amazon scrapers for a list of queries and
persists the results into products_raw (status='pending'). The existing
ingestion workers then download images, embed them, and finalize into
the searchable products table.

Usage (CLI):
    python -m workers.crawler \
        --sources telemart amazon \
        --queries "smart watch" "wireless earbuds" "running shoes"

    python -m workers.crawler --queries-file queries.txt --sources telemart

After crawling, run the pipeline:
    python -m workers.download_worker
    python -m workers.embedding_worker
    python -m workers.product_finalizer_worker
"""

import argparse
import sys

from backend.scrapers.telemart import scrape_telemart
from backend.scrapers.amazon import scrape_amazon_sync
from backend.services.scraper_import_service import (
    persist_products
)


# Default category queries to seed a broad MVP catalog.
DEFAULT_QUERIES = [
    "smart watch",
    "wireless earbuds",
    "running shoes",
    "sneakers",
    "headphones",
    "backpack",
    "t shirt",
    "hoodie"
]


def run_crawler(
    queries,
    sources=("telemart", "amazon"),
    telemart_max_pages=5,
    amazon_max_products=20,
    verbose=True
):
    """
    Run scrapers for each query/source and persist to products_raw.
    Returns a summary dict.
    """

    summary = {
        "queries": list(queries),
        "sources": list(sources),
        "scraped": 0,
        "inserted": 0,
        "skipped": 0,
        "per_source": {}
    }

    all_products = []

    for source in sources:

        source_inserted = 0
        source_scraped = 0

        for query in queries:

            if verbose:

                print(
                    f"\n=== [{source}] query={query!r} ==="
                )

            try:

                if source == "telemart":

                    products = scrape_telemart(
                        query,
                        max_pages=telemart_max_pages,
                        verbose=verbose
                    )

                elif source == "amazon":

                    products = scrape_amazon_sync(
                        query,
                        max_products=amazon_max_products,
                        headless=True,
                        verbose=verbose
                    )

                else:

                    print(f"Unknown source: {source}")

                    continue

            except Exception as e:

                print(
                    f"[{source}] query={query!r} FAILED: {e}"
                )

                continue

            source_scraped += len(products)

            inserted, skipped = persist_products(products)

            source_inserted += inserted

            summary["skipped"] += skipped

            if verbose:

                print(
                    f"[{source}] {query!r}: "
                    f"scraped={len(products)} "
                    f"inserted={inserted} skipped={skipped}"
                )

        summary["per_source"][source] = {
            "scraped": source_scraped,
            "inserted": source_inserted
        }

        summary["scraped"] += source_scraped
        summary["inserted"] += source_inserted

    if verbose:

        print("\n==============================")
        print("CRAWL SUMMARY")
        print(f"  scraped:  {summary['scraped']}")
        print(f"  inserted: {summary['inserted']}")
        print(f"  skipped:  {summary['skipped']}")
        for src, stats in summary["per_source"].items():
            print(
                f"  {src}: scraped={stats['scraped']} "
                f"inserted={stats['inserted']}"
            )
        print("==============================")

    return summary


# ----------------------------------------------------------
# CLI
# ----------------------------------------------------------

def _parse_args(argv):

    parser = argparse.ArgumentParser(
        description="ShopSense catalog crawler"
    )

    parser.add_argument(
        "--queries",
        nargs="+",
        default=DEFAULT_QUERIES,
        help="Search queries to crawl (default: a broad MVP set)"
    )

    parser.add_argument(
        "--queries-file",
        help="Path to a file with one query per line (overrides --queries)"
    )

    parser.add_argument(
        "--sources",
        nargs="+",
        default=["telemart"],
        choices=["telemart", "amazon"],
        help="Which scrapers to run (default: telemart)"
    )

    parser.add_argument(
        "--telemart-max-pages",
        type=int,
        default=5,
        help="Max pages per Telemart query (default: 5)"
    )

    parser.add_argument(
        "--amazon-max-products",
        type=int,
        default=20,
        help="Max products per Amazon query (default: 20)"
    )

    return parser.parse_args(argv)


def main(argv=None):

    args = _parse_args(argv or sys.argv[1:])

    queries = args.queries

    if args.queries_file:

        with open(args.queries_file, encoding="utf-8") as f:

            queries = [
                line.strip()
                for line in f
                if line.strip()
            ]

    run_crawler(
        queries=queries,
        sources=args.sources,
        telemart_max_pages=args.telemart_max_pages,
        amazon_max_products=args.amazon_max_products,
        verbose=True
    )


if __name__ == "__main__":

    main()
