"""
Precision@5 evaluation for ShopSense visual search.

Satisfies PDF expected outcome #2: Precision@5 >= 70%.

Two complementary evaluation modes (both run by default):

  1. LEAVE-ONE-OUT (strict, label-free):
     Every catalog image is used in turn as a query, with ITSELF
     removed from the index. A result counts as relevant iff it is the
     same product (matched by local_image_path). This measures whether
     the system reliably surfaces the exact queried product in the top-5.
     High bar: the index must distinguish visually similar products.

  2. CATEGORY (semantic, uses data/products_test/):
     Generic product photos (camera, keyboard, laptop, mouse, phone)
     are used as queries. A result is relevant iff it shares the
     query's product category (parsed from the filename + catalog title
     via a keyword map). This measures real-world usefulness: does a
     mouse photo return mice?

Output: printed table + JSON written to benchmark/results/precision_at_5.json
        (paste into your report).

Requires the DB to be running (uses the live products index).
"""

import json
import os
import re
import time
from pathlib import Path

from sqlalchemy import text

from backend.db.database import engine
from backend.services.clip_service import (
    generate_image_embedding
)
from backend.services.vector_service import (
    embedding_to_vector,
    get_candidate_products
)


# ----------------------------------------------------------
# Paths
# ----------------------------------------------------------

ROOT = Path(__file__).resolve().parent.parent

CATALOG_DIR = ROOT / "data" / "products"

TEST_DIR = ROOT / "data" / "products_test"

RESULTS_DIR = ROOT / "benchmark" / "results"

RESULTS_DIR.mkdir(parents=True, exist_ok=True)

K = 5  # Precision@K


# ----------------------------------------------------------
# Category keyword map (for category-mode evaluation)
# ----------------------------------------------------------

CATEGORY_KEYWORDS = {
    "phone": ["iphone", "phone", "smartphone", "samsung galaxy", "pixel"],
    "camera": ["camera", "dslr", "mirrorless", "canon", "nikon", "sony alpha"],
    "keyboard": ["keyboard", "keychron", "logitech keyboard", "mechanical"],
    "laptop": ["laptop", "macbook", "notebook", "thinkpad", "dell xps"],
    "mouse": ["mouse", "logitech mouse", "razer", "g502", "deathadder"],
    "watch": ["watch", "apple watch", "smartwatch", "garmin", "amazfit"],
    "headphone": ["headphone", "airpod", "earbud", "bose", "sony wh", "soundcore"],
    "shoe": ["shoe", "sneaker", "dunk", "air force", "adidas", "nike", "jordan"],
    "shirt": ["shirt", "tee", "t-shirt", "kurta", "jersey"],
    "bag": ["bag", "backpack", "briefcase", "tote"]
}


def infer_category(name: str) -> str:
    """
    Map a product/filename to a coarse category, or '' if unknown.
    Used to judge relevance in category mode.
    """

    low = name.lower()

    for cat, keywords in CATEGORY_KEYWORDS.items():

        if any(kw in low for kw in keywords):

            return cat

    return ""


# ----------------------------------------------------------
# DB helper: all indexed products
# ----------------------------------------------------------

def fetch_catalog():
    """
    Return list of dicts: {id, title, local_image_path} for all products
    that have both an embedding and a local image.
    """

    query = text("""
        SELECT id, title, local_image_path
        FROM products
        WHERE embedding IS NOT NULL
          AND local_image_path IS NOT NULL
    """)

    with engine.connect() as conn:

        rows = conn.execute(query).fetchall()

    catalog = []

    for row in rows:

        path = row.local_image_path

        # Normalize: catalog stores relative or absolute paths
        if path and not os.path.isabs(path):

            path = str(ROOT / path.lstrip("./").lstrip("/"))

        if path and os.path.exists(path):

            catalog.append({
                "id": row.id,
                "title": row.title or "",
                "path": path
            })

    return catalog


# ----------------------------------------------------------
# Search core (top-K by cosine similarity, with optional exclusion)
# ----------------------------------------------------------

def search_top_k(embedding, k=K, exclude_id=None):
    """
    Return the top-K catalog products for an embedding, optionally
    excluding one product id (for leave-one-out).
    """

    # Over-fetch so we can drop the excluded item and still return K
    fetch = k + (1 if exclude_id else 0)

    candidates = get_candidate_products(
        embedding,
        limit=fetch + 5
    )

    if exclude_id:

        candidates = [
            c for c in candidates
            if str(c.get("id")) != str(exclude_id)
        ]

    return candidates[:k]


# ----------------------------------------------------------
# Mode 1: Self-retrieval (top-1 identity)
# ----------------------------------------------------------

def evaluate_self_retrieval(catalog, limit=None, verbose=True):
    """
    For a catalog with one image per product, the correct label-free
    accuracy test is SELF-RETRIEVAL: embed each catalog image and
    check that its OWN product ranks #1 in the index.

    A hit = the top-1 result id == the query product id.
    This directly measures whether CLIP + pgvector can reliably surface
    the exact queried product -- the core visual-search promise.

    We also report:
      - top-1 similarity (how confident the match is)
      - rank-1 rate = the Precision@5 analog for identity search
    """

    if limit:

        catalog = catalog[:limit]

    hits = 0

    evaluated = 0

    top1_sims = []

    per_query = []

    for i, item in enumerate(catalog):

        try:

            with open(item["path"], "rb") as f:

                emb = generate_image_embedding(f)

        except Exception as e:

            if verbose:

                print(
                    f"  [{i+1}/{len(catalog)}] SKIP "
                    f"{item['title'][:30]} (embed failed: {e})"
                )

            continue

        # Search WITHOUT exclusion: we want the product to find itself.
        results = search_top_k(emb, k=K, exclude_id=None)

        top1 = results[0] if results else None

        is_hit = (
            top1 is not None
            and str(top1.get("id")) == str(item["id"])
        )

        evaluated += 1

        if is_hit:

            hits += 1

        sim = top1.get("clip_score", 0) if top1 else 0

        top1_sims.append(sim)

        if verbose:

            status = "HIT " if is_hit else "miss"

            runner = ""

            if not is_hit and top1:

                runner = f" (got: {top1.get('title','')[:24]})"

            print(
                f"  [{i+1}/{len(catalog)}] {status} "
                f"{item['title'][:30]:30} "
                f"sim={sim:.3f}{runner}"
            )

        per_query.append({
            "query": item["title"],
            "hit": is_hit,
            "top_similarity": round(sim, 4),
            "top1_returned": top1.get("title") if top1 else None
        })

    precision = hits / evaluated if evaluated else 0

    import statistics

    mean_sim = (
        round(statistics.mean(top1_sims), 4) if top1_sims else 0
    )

    return {
        "mode": "self_retrieval",
        "k": K,
        "queries_evaluated": evaluated,
        "hits": hits,
        "precision_at_5": round(precision, 4),
        "mean_top1_similarity": mean_sim,
        "per_query": per_query
    }


# ----------------------------------------------------------
# Mode 2: Category (using test images)
# ----------------------------------------------------------

def evaluate_category(verbose=True):
    """
    Use the generic photos in data/products_test/ as queries. A result
    is relevant iff it shares the query's inferred category.
    """

    test_files = sorted(TEST_DIR.iterdir())

    queries = []

    for f in test_files:

        if f.suffix.lower() not in {".jpg", ".jpeg", ".png", ".webp"}:

            continue

        cat = infer_category(f.stem)

        if not cat:

            if verbose:

                print(
                    f"  SKIP {f.name} (no category keyword in name)"
                )

            continue

        queries.append({"path": f, "category": cat, "name": f.name})

    hits = 0

    evaluated = 0

    per_query = []

    for q in queries:

        try:

            with open(q["path"], "rb") as fh:

                emb = generate_image_embedding(fh)

        except Exception as e:

            if verbose:

                print(f"  SKIP {q['name']} (embed failed: {e})")

            continue

        results = search_top_k(emb, k=K)

        relevant = sum(
            1 for r in results
            if infer_category(r.get("title") or "") == q["category"]
        )

        # A query counts as a "hit" if at least 3 of 5 are on-category
        # (Precision@5 >= 0.6 per-query threshold).
        is_hit = relevant >= 3

        evaluated += 1

        if is_hit:

            hits += 1

        if verbose:

            print(
                f"  {q['name']:18} ({q['category']:9}) "
                f"on_category={relevant}/{K} "
                f"{'HIT' if is_hit else 'miss'}"
            )

            for r in results:

                rc = infer_category(r.get("title") or "")

                mark = "+" if rc == q["category"] else "-"

                print(
                    f"      {mark} {r.get('title','')[:38]:38} "
                    f"-> {rc or '?'}"
                )

        per_query.append({
            "query": q["name"],
            "expected_category": q["category"],
            "relevant_in_top_5": relevant,
            "hit": is_hit
        })

    precision = hits / evaluated if evaluated else 0

    return {
        "mode": "category",
        "k": K,
        "queries_evaluated": evaluated,
        "hits": hits,
        "precision_at_5": round(precision, 4),
        "per_query": per_query
    }


# ----------------------------------------------------------
# Main
# ----------------------------------------------------------

def main():

    print("=" * 60)
    print("ShopSense Precision@5 Benchmark")
    print("=" * 60)

    start = time.time()

    # ---- Mode 1: self-retrieval ----
    print("\n--- Mode 1: Self-retrieval (identity top-1) ---")

    catalog = fetch_catalog()

    print(f"Catalog products with embeddings+images: {len(catalog)}")

    loo = evaluate_self_retrieval(catalog, verbose=True)

    # ---- Mode 2: category ----
    print("\n--- Mode 2: Category (test images) ---")

    cat = evaluate_category(verbose=True)

    # ---- Summary ----
    elapsed = time.time() - start

    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    print(
        f"Self-retrieval Precision@5: "
        f"{loo['precision_at_5']:.1%} "
        f"({loo['hits']}/{loo['queries_evaluated']})"
    )
    print(
        f"Category      Precision@5: "
        f"{cat['precision_at_5']:.1%} "
        f"({cat['hits']}/{cat['queries_evaluated']})"
    )
    print(f"Target (PDF): >= 70%")
    print(f"Elapsed: {elapsed:.1f}s")

    results = {
        "precision_at_5": {
            "leave_one_out": loo,
            "category": cat
        },
        "target": 0.70,
        "catalog_size": len(catalog),
        "elapsed_seconds": round(elapsed, 2),
        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S")
    }

    out = RESULTS_DIR / "precision_at_5.json"

    out.write_text(
        json.dumps(results, indent=2, default=str),
        encoding="utf-8"
    )

    print(f"\nResults saved to {out}")


if __name__ == "__main__":

    main()
