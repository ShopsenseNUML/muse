# ShopSense Benchmarks

Evaluation scripts that measure the two measurable PDF objectives:

| Objective | Target | Script |
|-----------|--------|--------|
| Precision@5 (visual matching) | ≥ 70% | `precision_at_k.py` |
| End-to-end latency | < 5 s | `latency_benchmark.py` |

## Prerequisites

- PostgreSQL + pgvector running (Docker: `docker compose up -d`)
- Catalog populated with embeddings (see `workers/import_folder_worker.py`)
- The `.shopsense` venv active

## Quick start

Run both benchmarks and write a consolidated report:

```bash
python -m benchmark.run
```

Run only one:

```bash
python -m benchmark.run --only precision
python -m benchmark.run --only latency
```

Results are written to `benchmark/results/`:

- `precision_at_5.json`
- `latency.json`
- `summary.json` (consolidated)

## Precision@5 — two modes

The metric is reported in two complementary ways so the evaluation is
robust even without hand-labeled data.

### Mode 1: Leave-one-out (strict, label-free)

Every catalog image is used in turn as a query, **with itself removed
from the index**. The top-5 results are retrieved, and the query counts
as a *hit* if a result shares the same product title. This is a strict
self-consistency test: it measures whether visually distinct products
stay separable.

### Mode 2: Category (semantic, uses test photos)

The generic product photos in `data/products_test/` (camera, keyboard,
laptop, mouse, phone) are used as queries. A result is *relevant* if it
shares the query's inferred category (from a keyword map). A query is a
*hit* if ≥ 3 of the top-5 are on-category. This measures real-world
usefulness — does a mouse photo surface mice?

The overall Precision@5 is the fraction of *queries* that were hits.

## Latency

Each search path (image, text, hybrid) is measured with:

- **Cold run**: first call (includes CLIP model load + DB pool warmup)
- **Warm runs** (10 by default): steady-state timing

Per-stage breakdowns (embed / analyze / DB search / rank) are captured
so the report can explain where time is spent. The pass/fail check uses
warm mean vs the 5 s target.

## Reproducing for the report

1. Scale the catalog toward the 5,000–10,000 target (see
   `workers/crawler.py`) and run the full ingestion pipeline
   (`download_worker` → `embedding_worker` → `product_finalizer_worker`).
2. Run `python -m benchmark.run`.
3. Copy the SUMMARY block from stdout, and/or the JSON in
   `benchmark/results/summary.json`, into the report's Evaluation
   section.

> Latency is CPU-bound on CPU-only machines (CLIP ViT-B/32 inference
> dominates). Numbers will be lower on a GPU host or AWS t3.medium as
> specified in the PDF.
