# ShopSense — AI Visual Search & Price Intelligence

Final Year Project (NUML). AI-powered visual search for Pakistani e-commerce:
snap a product photo (or type, including Roman Urdu) and find it across local
platforms with live price comparison.

## Repo layout

```
muse/
├── backend/            # FastAPI backend (Python). All imports are `backend.*`
│   ├── main.py         # app entrypoint  →  uvicorn backend.main:app
│   ├── api/            # REST routers (search, products, comparison, admin, upload)
│   ├── services/       # CLIP, vector search, Roman Urdu, ranking, comparison…
│   ├── workers/        # ingestion pipeline workers
│   ├── scrapers/       # platform scrapers
│   ├── providers/      # price-provider adapters (Daraz, Telemart…)
│   ├── scripts/        # init_db, seeders, db check
│   └── data/           # product images, Roman Urdu dictionary
├── flutter_app/        # Flutter mobile/web app (wired to the backend API)
├── postgres/
│   └── schema.sql      # canonical DB schema (PostgreSQL + pgvector)
├── benchmark/          # precision/latency benchmarks  (python -m benchmark.run)
├── gui/                # standalone Tkinter test client (python -m gui.app)
├── docker-compose.yml  # postgres (pgvector) + redis
└── requirements.txt    # backend Python dependencies
```

## Backend quickstart

```bash
# 1. Infrastructure
docker compose up -d            # postgres:5432, redis:6379

# 2. Python environment
python -m venv .venv
source .venv/bin/activate       # Windows: .venv\Scripts\activate
pip install -r requirements.txt

# 3. Database schema
python -m backend.scripts.init_db

# 4. Run the API  (from the repo root — no path hacks needed)
uvicorn backend.main:app --host 127.0.0.1 --port 8000
```

- Swagger UI: http://127.0.0.1:8000/docs
- Health check: http://127.0.0.1:8000/health
- Optional demo data: `python -m backend.scripts.seed_sample_products`
  (needs the CLIP model cached; set `HF_HUB_OFFLINE=1` to reuse it)

All file paths inside `backend/` are resolved from the package location, so
commands work from any working directory. The API base URL used by the app
lives in `flutter_app/lib/core/constants/api_constants.dart`
(default `http://127.0.0.1:8000`; use `http://10.0.2.2:8000` on the Android
emulator, or your machine's LAN IP on a physical device).

## Flutter app quickstart

```bash
cd flutter_app
flutter pub get
flutter run                    # device / emulator
flutter build web --release    # web build → flutter_app/build/web
```

## Notes

- `backend/data/` holds pipeline images; `postgres/schema.sql` is the
  canonical schema (applied by `backend.scripts.init_db`).
- `gui/` and `benchmark/` are self-contained tools that only talk to the
  backend over HTTP.
