"""
End-to-end latency benchmark for ShopSense.

Satisfies PDF expected outcome #5: end-to-end response time < 5s.

Measures three search paths, each repeated N times and reported as
mean / median / p95 / max, with per-stage breakdowns so the report can
explain where time is spent:

    - IMAGE search  : embed + DB vector search
    - TEXT  search  : query intelligence + metadata search + rank
    - HYBRID search : embed + query intelligence + vector + rank

Also measures COLD vs WARM latency:
    - cold = first call (includes CLIP model load + DB pool warmup)
    - warm = subsequent calls (steady state)

Output: printed table + JSON to benchmark/results/latency.json
Requires the DB to be running.
"""

import json
import os
import statistics
import time
from pathlib import Path

from backend.services.clip_service import (
    generate_image_embedding
)
from backend.services.hybrid_search_service import (
    hybrid_search
)
from backend.services.query_intelligence_service import (
    analyze_query
)
from backend.services.search_service import (
    search_by_metadata
)
from backend.services.vector_service import (
    get_candidate_products,
    hybrid_search_products
)


# ----------------------------------------------------------
# Config
# ----------------------------------------------------------

ROOT = Path(__file__).resolve().parent.parent

CATALOG_DIR = ROOT / "data" / "products"

RESULTS_DIR = ROOT / "benchmark" / "results"

RESULTS_DIR.mkdir(parents=True, exist_ok=True)

TARGET_SECONDS = 5.0  # PDF target

WARM_RUNS = 10  # measured runs after the cold run

# Representative queries for text/hybrid (mix English + Roman Urdu)
TEXT_QUERIES = [
    "smart watch under 5000",
    "laal jora",
    "nike sneakers",
    "wireless earbuds",
    "iphone"
]


# ----------------------------------------------------------
# Helpers
# ----------------------------------------------------------

def _sample_image():
    """Return an open file handle to a representative catalog image."""

    for f in sorted(CATALOG_DIR.iterdir()):

        if f.suffix.lower() in {".jpg", ".jpeg", ".png", ".webp"}:

            return open(f, "rb")

    raise FileNotFoundError("No catalog image found to benchmark")


def _stats(samples):
    """Compute mean/median/p95/max from a list of seconds."""

    if not samples:

        return None

    s = sorted(samples)

    p95_idx = max(0, int(len(s) * 0.95) - 1)

    return {
        "mean": round(statistics.mean(s), 4),
        "median": round(statistics.median(s), 4),
        "p95": round(s[p95_idx], 4),
        "max": round(s[-1], 4),
        "min": round(s[0], 4),
        "n": len(s)
    }


# ----------------------------------------------------------
# Benchmarks
# ----------------------------------------------------------

def bench_image_search(warm_runs=WARM_RUNS, verbose=True):
    """
    Measure: file open + CLIP embed + pgvector top-K search.
    The cold run captures model-load; warm runs are steady state.
    """

    cold_time = None

    warm = []

    # ---- Cold run ----
    fh = _sample_image()

    t0 = time.time()

    emb = generate_image_embedding(fh)

    t1 = time.time()

    results = get_candidate_products(emb, limit=10)

    t2 = time.time()

    fh.close()

    cold_time = round(t2 - t0, 4)

    cold_stages = {
        "embed": round(t1 - t0, 4),
        "vector_search": round(t2 - t1, 4),
        "total": cold_time
    }

    if verbose:

        print(
            f"  COLD  total={cold_time}s "
            f"(embed={cold_stages['embed']}s "
            f"search={cold_stages['vector_search']}s)"
        )

    # ---- Warm runs ----
    for i in range(warm_runs):

        fh = _sample_image()

        t0 = time.time()

        emb = generate_image_embedding(fh)

        t1 = time.time()

        get_candidate_products(emb, limit=10)

        t2 = time.time()

        fh.close()

        total = t2 - t0

        warm.append(total)

        if verbose:

            print(
                f"  warm {i+1:2}/{warm_runs}: {total:.3f}s "
                f"(embed={t1-t0:.3f}s search={t2-t1:.3f}s)"
            )

    return {
        "path": "image_search",
        "cold_seconds": cold_time,
        "cold_stages": cold_stages,
        "warm": _stats(warm),
        "meets_target": (
            statistics.mean(warm) < TARGET_SECONDS if warm else False
        )
    }


def bench_text_search(queries=TEXT_QUERIES, verbose=True):
    """
    Measure: query analysis (incl. Roman Urdu translation) +
    metadata SQL search.
    """

    cold = None

    warm = []

    for i, q in enumerate(queries):

        t0 = time.time()

        analysis = analyze_query(q)

        t1 = time.time()

        results = search_by_metadata(analysis, limit=50)

        t2 = time.time()

        total = t2 - t0

        if i == 0:

            cold = round(total, 4)

            if verbose:

                print(
                    f"  COLD  '{q}': {total:.3f}s "
                    f"(analyze={t1-t0:.3f}s search={t2-t1:.3f}s)"
                )

        else:

            warm.append(total)

            if verbose:

                print(
                    f"  warm  '{q}': {total:.3f}s "
                    f"(analyze={t1-t0:.3f}s search={t2-t1:.3f}s)"
                )

    return {
        "path": "text_search",
        "cold_seconds": cold,
        "warm": _stats(warm),
        "meets_target": (
            statistics.mean(warm) < TARGET_SECONDS if warm else True
        )
    }


def bench_hybrid_search(verbose=True):
    """
    Measure: embed + query analysis + hybrid (vector + metadata rank).
    Uses one image + one text query, repeated.
    """

    warm = []

    text_query = "black smart watch under 10000"

    # Cold
    fh = _sample_image()

    t0 = time.time()

    emb = generate_image_embedding(fh)

    analysis = analyze_query(text_query)

    t1 = time.time()

    hybrid_search(emb, analysis, limit=50)

    t2 = time.time()

    fh.close()

    cold = round(t2 - t0, 4)

    if verbose:

        print(
            f"  COLD  total={cold}s "
            f"(prepare={t1-t0:.3f}s rank={t2-t1:.3f}s)"
        )

    # Warm
    for i in range(WARM_RUNS):

        fh = _sample_image()

        t0 = time.time()

        emb = generate_image_embedding(fh)

        analysis = analyze_query(text_query)

        t1 = time.time()

        hybrid_search(emb, analysis, limit=50)

        t2 = time.time()

        fh.close()

        total = t2 - t0

        warm.append(total)

        if verbose:

            print(
                f"  warm {i+1:2}/{WARM_RUNS}: {total:.3f}s "
                f"(prepare={t1-t0:.3f}s rank={t2-t1:.3f}s)"
            )

    return {
        "path": "hybrid_search",
        "cold_seconds": cold,
        "warm": _stats(warm),
        "meets_target": (
            statistics.mean(warm) < TARGET_SECONDS if warm else False
        )
    }


# ----------------------------------------------------------
# Main
# ----------------------------------------------------------

def main():

    print("=" * 60)
    print("ShopSense Latency Benchmark")
    print(f"Target: end-to-end < {TARGET_SECONDS}s (warm)")
    print("=" * 60)

    results = {}

    print("\n--- Image search (embed + vector) ---")

    results["image_search"] = bench_image_search()

    print("\n--- Text search (analyze + metadata) ---")

    results["text_search"] = bench_text_search()

    print("\n--- Hybrid search (embed + analyze + rank) ---")

    results["hybrid_search"] = bench_hybrid_search()

    # ---- Summary ----
    print("\n" + "=" * 60)
    print("SUMMARY (warm mean)")
    print("=" * 60)

    for path, r in results.items():

        warm = r["warm"]

        mean = warm["mean"] if warm else r["cold_seconds"]

        ok = "PASS" if r["meets_target"] else "FAIL"

        print(
            f"  {path:14}: {mean:.3f}s  [{ok}]  "
            f"(cold {r['cold_seconds']:.3f}s)"
        )

    print(f"\nTarget: < {TARGET_SECONDS}s")

    out = {
        "target_seconds": TARGET_SECONDS,
        "results": results,
        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S")
    }

    f = RESULTS_DIR / "latency.json"

    f.write_text(json.dumps(out, indent=2), encoding="utf-8")

    print(f"\nResults saved to {f}")


if __name__ == "__main__":

    main()
