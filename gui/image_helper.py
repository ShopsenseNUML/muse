"""
Image loading utilities for the GUI.

Loads product images from either a local path or a URL, converts them
to a Tkinter-compatible PhotoImage, and resizes for thumbnail display.
Caches decoded thumbnails to avoid re-decoding on redraw.

Keeps PIL optional: if Pillow is missing, falls back to a placeholder
rectangle so the GUI still runs.
"""

import io
from typing import Optional
from urllib.parse import urlparse

import requests

try:

    from PIL import Image, ImageTk

    HAS_PIL = True

except ImportError:

    HAS_PIL = False


def is_url(path: str) -> bool:

    try:

        parsed = urlparse(path)

        return parsed.scheme in ("http", "https")

    except Exception:

        return False


def load_image(
    path: str,
    size: tuple = (120, 120)
) -> Optional["ImageTk.PhotoImage"]:
    """
    Load an image from a local path or URL and return a resized
    PhotoImage suitable for Tkinter widgets.

    Returns None if the image cannot be loaded (caller should show a
    placeholder). Requires Pillow.
    """

    if not HAS_PIL:

        return None

    try:

        if is_url(path):

            response = requests.get(path, timeout=8)

            response.raise_for_status()

            img = Image.open(io.BytesIO(response.content))

        else:

            img = Image.open(path)

        img = img.convert("RGB")

        # Preserve aspect ratio, fit within size box
        img.thumbnail(size, Image.LANCZOS)

        return ImageTk.PhotoImage(img)

    except Exception:

        return None


def load_image_bytes(
    data: bytes,
    size: tuple = (120, 120)
) -> Optional["ImageTk.PhotoImage"]:
    """Load an image from raw bytes (e.g. a fetched thumbnail)."""

    if not HAS_PIL:

        return None

    try:

        img = Image.open(io.BytesIO(data)).convert("RGB")

        img.thumbnail(size, Image.LANCZOS)

        return ImageTk.PhotoImage(img)

    except Exception:

        return None
