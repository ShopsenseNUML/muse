"""
ShopSense test GUI (Tkinter).

A standalone desktop client that exercises EVERY feature of the
ShopSense backend: image / text / hybrid search, price comparison
(text + image), catalog browsing, and admin stats.

This folder (gui/) is intentionally self-contained and separate from
the backend so it can be deleted cleanly when you move to the Flutter
app. It only talks to the backend over HTTP.

Requirements:
    pip install requests pillow

Usage:
    python -m gui.app
    python -m gui.app --url http://127.0.0.1:8000

Make sure the backend is running first:
    uvicorn backend.main:app --reload
"""

import argparse
import threading
import webbrowser
from pathlib import Path
from tkinter import (
    Tk, ttk, filedialog, messagebox, StringVar, Text, END, WORD
)
from typing import Optional

from gui.api_client import ShopSenseClient, ShopSenseAPIError
from gui.image_helper import load_image, HAS_PIL


# ----------------------------------------------------------
# Theme / colors
# ----------------------------------------------------------

BG = "#f5f5f5"
ACCENT = "#2563eb"
CARD_BG = "#ffffff"
GOOD = "#16a34a"
WARN = "#dc2626"


class ShopSenseGUI:

    def __init__(self, root: Tk, client: ShopSenseClient):

        self.root = root
        self.client = client
        self.current_image_path: Optional[str] = None
        # Keep references to PhotoImages so they are not garbage-collected
        self._photo_refs = []

        root.title("ShopSense — Test Client")
        root.geometry("1000x720")
        root.configure(bg=BG)

        self.notebook = ttk.Notebook(root)
        self.notebook.pack(fill="both", expand=True, padx=8, pady=8)

        self._build_image_tab()
        self._build_text_tab()
        self._build_hybrid_tab()
        self._build_comparison_tab()
        self._build_catalog_tab()
        self._build_admin_tab()

    # ==========================================================
    # Shared widgets
    # ==========================================================

    def _make_scroll_results(self, parent) -> Text:
        """A read-only text box for showing JSON-ish results."""

        box = Text(
            parent,
            wrap=WORD,
            font=("Consolas", 10),
            bg=CARD_BG,
            relief="flat",
            padx=10,
            pady=10
        )
        return box

    def _run_async(self, func, *args):
        """
        Run a blocking API call in a background thread so the UI stays
        responsive. Disables the calling button until done.
        """

        def worker():

            try:

                func(*args)

            except ShopSenseAPIError as e:

                self.root.after(
                    0, lambda: messagebox.showerror("API Error", str(e))
                )

            except Exception as e:

                self.root.after(
                    0,
                    lambda: messagebox.showerror(
                        "Error", f"{type(e).__name__}: {e}"
                    )
                )

        threading.Thread(target=worker, daemon=True).start()

    def _render_results(self, box: Text, items: list, key_title: str = "title"):
        """Render a list of result dicts into a text box."""

        box.delete("1.0", END)

        if not items:

            box.insert(END, "No results.\n")

            return

        self._photo_refs.clear()

        for i, item in enumerate(items, 1):

            title = str(item.get(key_title) or item.get("name") or "—")
            score = item.get("final_score") or item.get("similarity") or item.get("clip_score")
            score_str = f"  (score: {score})" if score is not None else ""
            brand = item.get("brand") or ""
            cat = item.get("category") or ""
            price = item.get("price")
            platform = item.get("platform") or ""

            box.insert(END, f"{i}. {title}{score_str}\n", "title")
            if brand or cat:
                box.insert(END, f"   {brand} · {cat}\n", "meta")
            if price is not None:
                box.insert(
                    END,
                    f"   PKR {price}  {('· ' + platform) if platform else ''}\n",
                    "price"
                )
            box.insert(END, "\n")

        box.tag_config("title", font=("Segoe UI", 11, "bold"), foreground=ACCENT)
        box.tag_config("meta", font=("Segoe UI", 9), foreground="#555")
        box.tag_config("price", font=("Segoe UI", 9, "bold"), foreground=GOOD)

    # ==========================================================
    # Tab 1: Image Search
    # ==========================================================

    def _build_image_tab(self):

        tab = ttk.Frame(self.notebook)
        self.notebook.add(tab, text="🔍 Image Search")

        top = ttk.Frame(tab)
        top.pack(fill="x", padx=10, pady=10)

        ttk.Button(top, text="Choose Image…", command=self._pick_image).pack(side="left")
        self.img_label = ttk.Label(top, text="No image selected", foreground="#888")
        self.img_label.pack(side="left", padx=10)

        self.img_search_btn = ttk.Button(
            top, text="Search", command=self._do_image_search
        )
        self.img_search_btn.pack(side="right")

        self.img_preview = ttk.Label(tab, text="", background=BG)
        self.img_preview.pack(pady=5)

        # Scrollable result area
        self.img_results = self._make_scroll_results(tab)
        self.img_results.pack(fill="both", expand=True, padx=10, pady=(0, 10))

    def _pick_image(self):

        path = filedialog.askopenfilename(
            title="Select a product image",
            filetypes=[
                ("Images", "*.jpg *.jpeg *.png *.webp *.avif"),
                ("All files", "*.*")
            ]
        )

        if path:

            self.current_image_path = path
            self.img_label.config(text=Path(path).name)
            self._show_preview(path)

    def _show_preview(self, path: str):

        photo = load_image(path, size=(180, 180))

        if photo:

            self._photo_refs.append(photo)
            self.img_preview.config(image=photo, text="")

        else:

            self.img_preview.config(image="", text="(preview unavailable)")

    def _do_image_search(self):

        if not self.current_image_path:

            messagebox.showinfo("Choose image", "Please choose an image first.")
            return

        self.img_search_btn.config(state="disabled")

        def go():

            data = self.client.search_image(self.current_image_path)

            self.root.after(
                0,
                lambda: self._render_results(
                    self.img_results, data.get("results", [])
                )
            )

            self.root.after(
                0,
                lambda: self.img_search_btn.config(state="normal")
            )

        self._run_async(lambda: self._guarded(go))

    # ==========================================================
    # Tab 2: Text Search
    # ==========================================================

    def _build_text_tab(self):

        tab = ttk.Frame(self.notebook)
        self.notebook.add(tab, text="📝 Text Search")

        top = ttk.Frame(tab)
        top.pack(fill="x", padx=10, pady=10)

        self.text_query = StringVar()
        ttk.Entry(top, textvariable=self.text_query, width=40).pack(side="left")
        self.text_btn = ttk.Button(
            top, text="Search", command=self._do_text_search
        )
        self.text_btn.pack(side="left", padx=8)

        hint = ttk.Label(
            tab,
            text="Try Roman Urdu:  laal jora  ·  sasta smart watch  ·  kale jootay under 5000",
            foreground="#888"
        )
        hint.pack(anchor="w", padx=12)

        self.text_results = self._make_scroll_results(tab)
        self.text_results.pack(fill="both", expand=True, padx=10, pady=(5, 10))

    def _do_text_search(self):

        q = self.text_query.get().strip()

        if not q:

            messagebox.showinfo("Enter query", "Please type a search query.")
            return

        self.text_btn.config(state="disabled")

        def go():

            data = self.client.search_text(q)

            translated = data.get("analysis", {}).get("translated_query", "")

            self.root.after(
                0,
                lambda: self._render_results(
                    self.text_results, data.get("results", [])
                )
            )

            if translated and translated.lower() != q.lower():

                self.root.after(
                    0,
                    lambda: messagebox.showinfo(
                        "Roman Urdu translated",
                        f'"{q}" → "{translated}"'
                    )
                )

            self.root.after(
                0, lambda: self.text_btn.config(state="normal")
            )

        self._run_async(lambda: self._guarded(go))

    # ==========================================================
    # Tab 3: Hybrid Search
    # ==========================================================

    def _build_hybrid_tab(self):

        tab = ttk.Frame(self.notebook)
        self.notebook.add(tab, text="🧬 Hybrid Search")

        top = ttk.Frame(tab)
        top.pack(fill="x", padx=10, pady=10)

        ttk.Button(
            top, text="Choose Image…", command=self._pick_hybrid_image
        ).pack(side="left")
        self.hybrid_img_label = ttk.Label(
            top, text="No image selected", foreground="#888"
        )
        self.hybrid_img_label.pack(side="left", padx=10)

        self.hybrid_query = StringVar()
        ttk.Entry(top, textvariable=self.hybrid_query, width=30).pack(side="left")
        self.hybrid_btn = ttk.Button(
            top, text="Search", command=self._do_hybrid_search
        )
        self.hybrid_btn.pack(side="left", padx=8)

        self.hybrid_results = self._make_scroll_results(tab)
        self.hybrid_results.pack(fill="both", expand=True, padx=10, pady=(5, 10))

        self._hybrid_image_path: Optional[str] = None

    def _pick_hybrid_image(self):

        path = filedialog.askopenfilename(
            title="Select a product image",
            filetypes=[("Images", "*.jpg *.jpeg *.png *.webp"), ("All", "*.*")]
        )

        if path:

            self._hybrid_image_path = path
            self.hybrid_img_label.config(text=Path(path).name)

    def _do_hybrid_search(self):

        if not getattr(self, "_hybrid_image_path", None):

            messagebox.showinfo("Choose image", "Please choose an image first.")
            return

        q = self.hybrid_query.get().strip()
        path = self._hybrid_image_path

        self.hybrid_btn.config(state="disabled")

        def go():

            data = self.client.search_hybrid(path, q)

            self.root.after(
                0,
                lambda: self._render_results(
                    self.hybrid_results, data.get("results", [])
                )
            )

            self.root.after(
                0, lambda: self.hybrid_btn.config(state="normal")
            )

        self._run_async(lambda: self._guarded(go))

    # ==========================================================
    # Tab 4: Price Comparison
    # ==========================================================

    def _build_comparison_tab(self):

        tab = ttk.Frame(self.notebook)
        self.notebook.add(tab, text="💰 Price Comparison")

        # --- text comparison ---
        text_frame = ttk.LabelFrame(tab, text="Compare by text query")
        text_frame.pack(fill="x", padx=10, pady=10)

        row = ttk.Frame(text_frame)
        row.pack(fill="x", padx=8, pady=8)

        self.cmp_query = StringVar(value="smart watch")
        ttk.Entry(row, textvariable=self.cmp_query, width=35).pack(side="left")
        self.cmp_text_btn = ttk.Button(
            row, text="Compare prices", command=self._do_compare_text
        )
        self.cmp_text_btn.pack(side="left", padx=8)

        # --- image comparison ---
        img_frame = ttk.LabelFrame(tab, text="Compare by product photo")
        img_frame.pack(fill="x", padx=10, pady=(0, 10))

        row2 = ttk.Frame(img_frame)
        row2.pack(fill="x", padx=8, pady=8)

        ttk.Button(
            row2, text="Choose Image…", command=self._pick_cmp_image
        ).pack(side="left")
        self.cmp_img_label = ttk.Label(
            row2, text="No image selected", foreground="#888"
        )
        self.cmp_img_label.pack(side="left", padx=10)
        self.cmp_img_btn = ttk.Button(
            row2, text="Compare prices", command=self._do_compare_image
        )
        self.cmp_img_btn.pack(side="left", padx=8)

        self._cmp_image_path: Optional[str] = None

        self.cmp_results = self._make_scroll_results(tab)
        self.cmp_results.pack(fill="both", expand=True, padx=10, pady=(0, 10))

    def _pick_cmp_image(self):

        path = filedialog.askopenfilename(
            title="Select a product image",
            filetypes=[("Images", "*.jpg *.jpeg *.png *.webp"), ("All", "*.*")]
        )

        if path:

            self._cmp_image_path = path
            self.cmp_img_label.config(text=Path(path).name)

    def _render_comparison(self, box: Text, data: dict):

        box.delete("1.0", END)

        comp = data.get("comparison", data)

        matched = data.get("matched_product")
        if matched:

            box.insert(
                END,
                f"Matched: {matched.get('title','?')}  "
                f"(similarity: {matched.get('similarity','?')})\n\n",
                "title"
            )

        translated = data.get("translated_query")
        if translated:

            box.insert(END, f"Query: {translated}\n\n", "meta")

        prices = comp.get("prices", [])
        for p in prices:

            if not p:

                box.insert(END, "  — provider unavailable —\n\n", "warn")

                continue

            best = comp.get("best", {}) or {}
            is_best = p.get("platform") == best.get("platform")

            tag = "best" if is_best else "price"

            marker = "🏆 " if is_best else "   "

            box.insert(
                END,
                f"{marker}{p.get('platform','?').upper():10}  "
                f"PKR {p.get('price','?')}\n",
                tag
            )
            box.insert(END, f"     {p.get('title','')[:60]}\n", "meta")

            url = p.get("url")
            if url:

                box.insert(END, f"     {url}\n\n", "url")

            else:

                box.insert(END, "\n")

        spread = comp.get("spread")
        if spread:

            box.insert(
                END,
                f"\n💰 Save up to PKR {spread['savings']} "
                f"({spread['savings_percent']}%)\n",
                "best"
            )

        box.tag_config("title", font=("Segoe UI", 11, "bold"), foreground=ACCENT)
        box.tag_config("best", font=("Segoe UI", 11, "bold"), foreground=GOOD)
        box.tag_config("price", font=("Segoe UI", 10), foreground="#333")
        box.tag_config("meta", font=("Segoe UI", 9), foreground="#666")
        box.tag_config("url", font=("Consolas", 8), foreground="#888")
        box.tag_config("warn", font=("Segoe UI", 9, "italic"), foreground=WARN)

    def _do_compare_text(self):

        q = self.cmp_query.get().strip()

        if not q:

            return

        self.cmp_text_btn.config(state="disabled")

        def go():

            data = self.client.compare_text(q)

            self.root.after(
                0, lambda: self._render_comparison(self.cmp_results, data)
            )

            self.root.after(
                0, lambda: self.cmp_text_btn.config(state="normal")
            )

        self._run_async(lambda: self._guarded(go))

    def _do_compare_image(self):

        if not getattr(self, "_cmp_image_path", None):

            messagebox.showinfo("Choose image", "Please choose an image first.")
            return

        path = self._cmp_image_path

        self.cmp_img_btn.config(state="disabled")

        def go():

            data = self.client.compare_image(path)

            self.root.after(
                0, lambda: self._render_comparison(self.cmp_results, data)
            )

            self.root.after(
                0, lambda: self.cmp_img_btn.config(state="normal")
            )

        self._run_async(lambda: self._guarded(go))

    # ==========================================================
    # Tab 5: Catalog
    # ==========================================================

    def _build_catalog_tab(self):

        tab = ttk.Frame(self.notebook)
        self.notebook.add(tab, text="📦 Catalog")

        top = ttk.Frame(tab)
        top.pack(fill="x", padx=10, pady=10)

        ttk.Button(
            top, text="Load Catalog", command=self._do_load_catalog
        ).pack(side="left")

        ttk.Label(top, text="Limit:").pack(side="left", padx=(10, 4))
        self.cat_limit = StringVar(value="50")
        ttk.Spinbox(
            top, from_=5, to=500, increment=5,
            textvariable=self.cat_limit, width=6
        ).pack(side="left")

        self.cat_results = self._make_scroll_results(tab)
        self.cat_results.pack(fill="both", expand=True, padx=10, pady=(0, 10))

    def _do_load_catalog(self):

        try:

            limit = int(self.cat_limit.get())

        except ValueError:

            limit = 50

        def go():

            data = self.client.list_products(limit=limit)

            products = data.get("products", [])

            self.root.after(
                0,
                lambda: self._render_results(
                    self.cat_results, products, key_title="title"
                )
            )

        self._run_async(lambda: self._guarded(go))

    # ==========================================================
    # Tab 6: Admin
    # ==========================================================

    def _build_admin_tab(self):

        tab = ttk.Frame(self.notebook)
        self.notebook.add(tab, text="⚙️ Admin")

        top = ttk.Frame(tab)
        top.pack(fill="x", padx=10, pady=10)

        ttk.Button(
            top, text="Refresh Stats", command=self._do_load_admin
        ).pack(side="left")

        self.admin_results = self._make_scroll_results(tab)
        self.admin_results.pack(fill="both", expand=True, padx=10, pady=(0, 10))

    def _do_load_admin(self):

        def go():

            import json

            catalog = self.client.catalog_stats()
            dictionary = self.client.dictionary_stats()
            pipeline = self.client.pipeline_stats()

            text = (
                "=== CATALOG ===\n"
                + json.dumps(catalog, indent=2)
                + "\n\n=== ROMAN URDU DICTIONARY ===\n"
                + json.dumps(dictionary, indent=2)
                + "\n\n=== INGESTION PIPELINE ===\n"
                + json.dumps(pipeline, indent=2)
            )

            self.root.after(
                0,
                lambda: self.admin_results.delete("1.0", END)
            )
            self.root.after(
                0,
                lambda: self.admin_results.insert("1.0", text)
            )

        self._run_async(lambda: self._guarded(go))

    # ==========================================================
    # Guarded runner (catches API errors)
    # ==========================================================

    def _guarded(self, func):

        try:

            func()

        except ShopSenseAPIError as e:

            self.root.after(
                0, lambda: messagebox.showerror("API Error", str(e))
            )


# ----------------------------------------------------------
# Launch
# ----------------------------------------------------------

def main():

    parser = argparse.ArgumentParser(description="ShopSense test GUI")

    parser.add_argument(
        "--url",
        default="http://127.0.0.1:8000",
        help="Backend base URL (default: http://127.0.0.1:8000)"
    )

    args = parser.parse_args()

    root = Tk()

    # Try a nicer theme if available
    try:

        ttk.Style().theme_use("clam")

    except Exception:

        pass

    client = ShopSenseClient(base_url=args.url)

    # Quick connectivity check on startup
    try:

        client.health()

    except Exception:

        messagebox.showwarning(
            "Backend not reachable",
            f"Could not reach {args.url}.\n\n"
            "Start the backend first:\n"
            "  uvicorn backend.main:app --reload"
        )

    ShopSenseGUI(root, client)

    root.mainloop()


if __name__ == "__main__":

    main()
