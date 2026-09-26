# ShopSense Test GUI

A standalone **Tkinter** desktop client that tests every feature of the
ShopSense backend. This folder is **completely separate** from the
backend — it only talks to it over HTTP — so you can delete the whole
`gui/` folder later when you move to the Flutter app.

## Tabs (one per feature)

| Tab | Tests |
|-----|-------|
| 🔍 Image Search | `POST /search/image` — upload a photo, get visually similar products |
| 📝 Text Search | `POST /search/text` — type a query (Roman Urdu auto-translated) |
| 🧬 Hybrid Search | `POST /search/hybrid` — image + text combined |
| 💰 Price Comparison | `POST /search/comparison/text` + `/image` — side-by-side Daraz/Telemart prices |
| 📦 Catalog | `GET /products/` — browse the indexed catalog |
| ⚙️ Admin | `GET /admin/*` — catalog stats, Roman Urdu dictionary size, pipeline status |

## Prerequisites

1. The **backend must be running**:
   ```bash
   uvicorn backend.main:app --reload
   ```
2. Install GUI deps (only `requests` + `Pillow`; Tkinter ships with Python):
   ```bash
   pip install -r gui/requirements.txt
   ```

## Run

From the project root:

```bash
python -m gui.app
```

Or point it at a different backend:

```bash
python -m gui.app --url http://127.0.0.1:8080
```

## How to test each feature

- **Image search**: tab 🔍 → *Choose Image…* (try `data/products/Nike Dunk Low Panda.jpg`) → *Search*
- **Text search**: tab 📝 → type `laal jora` or `sasta smart watch under 5000` → *Search*
- **Hybrid**: tab 🧬 → choose an image + type a query → *Search*
- **Price comparison**: tab 💰 → type `smart watch` → *Compare prices*, OR choose an image → *Compare prices*
- **Catalog**: tab 📦 → *Load Catalog*
- **Admin**: tab ⚙️ → *Refresh Stats*

API calls run in background threads so the window stays responsive.
Errors (e.g. backend down) show a dialog.

## Delete when done

```bash
# Windows
rmdir /s /q gui
# Or just delete the folder in your editor.
```

No backend code references `gui/`, so removing it will not affect anything.
