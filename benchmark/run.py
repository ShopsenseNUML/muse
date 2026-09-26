"""
Run all ShopSense benchmarks in sequence.

Usage:
    python -m benchmark.run                 # run both
    python -m benchmark.run --only precision
    python -m benchmark.run --only latency

Writes results to benchmark/results/*.json and prints a summary table.
"""

import argparse
import json
import sys
import time
from pathlib import Path


RESULTS_DIR = (
    Path(__file__).resolve().parent / "results"
)


def main(argv=None):

    parser = argparse.ArgumentParser(
        description="Run ShopSense benchmarks"
    )

    parser.add_argument(
        "--only",
        choices=["precision", "latency"],
        help="Run only one benchmark (default: both)"
    )

    args = parser.parse_args(argv or sys.argv[1:])

    print("=" * 60)
    print("ShopSense Benchmark Suite")
    print("=" * 60)

    overall = {}

    # ---- Precision ----
    if args.only in (None, "precision"):

        print("\n>>> Precision@5\n")

        start = time.time()

        # Import + run lazily so a DB-down error in one doesn't
        # block the other.
        from benchmark import precision_at_k

        precision_at_k.main()

        overall["precision_elapsed"] = round(
            time.time() - start, 2
        )

    # ---- Latency ----
    if args.only in (None, "latency"):

        print("\n>>> Latency\n")

        start = time.time()

        from benchmark import latency_benchmark

        latency_benchmark.main()

        overall["latency_elapsed"] = round(
            time.time() - start, 2
        )

    # ---- Final consolidated report ----
    print("\n" + "=" * 60)
    print("ALL BENCHMARKS COMPLETE")
    print("=" * 60)

    consolidated = {
        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
        **overall
    }

    # Merge the individual result files into one summary
    for name in ["precision_at_5", "latency"]:

        p = RESULTS_DIR / f"{name}.json"

        if p.exists():

            consolidated[name] = json.loads(
                p.read_text(encoding="utf-8")
            )

    out = RESULTS_DIR / "summary.json"

    out.write_text(
        json.dumps(consolidated, indent=2, default=str),
        encoding="utf-8"
    )

    print(f"\nConsolidated report: {out}")


if __name__ == "__main__":

    main()
