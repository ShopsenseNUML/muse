"""
Roman Urdu -> English query translation.

Objective (PDF #3): provide basic Roman Urdu query support through a
curated dictionary of 200+ common shopping terms.

This module loads backend/data/roman_urdu_dict.json at import time and
exposes:
    - translate_query(query)  -> str   (English-normalized query)
    - analyze_translation(query) -> dict (debug info + per-token result)

Matching strategy:
    1. Multi-word phrases are matched first (longest first) so that
       "laal jora" -> "red dress" rather than "red dress" via two
       separate single-word matches.
    2. Remaining single tokens are matched against the dictionary.
    3. Unknown tokens are kept as-is (they may already be English, e.g.
       brand names like "samsung" or model names).
"""

import json
import re

from functools import lru_cache
from pathlib import Path



DICT_PATH = (
    Path(__file__).resolve()
    .parent.parent
    / "data"
    / "roman_urdu_dict.json"
)



# ----------------------------------------------------------
# Load + flatten the dictionary into lookup structures.
# ----------------------------------------------------------

def _load_dictionary():

    if not DICT_PATH.exists():

        raise FileNotFoundError(
            f"Roman Urdu dictionary not found: {DICT_PATH}"
        )

    raw = json.loads(
        DICT_PATH.read_text(encoding="utf-8")
    )

    single = {}
    multi = {}

    for category, mapping in raw.items():

        if category == "_meta":

            continue

        for roman_word, english in mapping.items():

            # Multi-word keys (contain whitespace) go to a separate map
            if " " in roman_word:

                multi[roman_word.lower()] = english

            else:

                single[roman_word.lower()] = english

    # Sort multi-word keys longest-first so longer phrases win.
    multi_sorted = sorted(
        multi.items(),
        key=lambda kv: len(kv[0]),
        reverse=True
    )

    return single, multi_sorted


_SINGLE, _MULTI = _load_dictionary()



# ----------------------------------------------------------
# Translation
# ----------------------------------------------------------

def _tokenize(query):

    # Lowercase, collapse whitespace, strip punctuation that is not
    # useful for product search (keep digits and currency symbols).
    query = query.lower().strip()

    query = re.sub(
        r"[^\w\s]",
        " ",
        query
    )

    query = re.sub(
        r"\s+",
        " ",
        query
    )

    return query



def translate_query(query):

    """
    Translate a Roman Urdu query to its English-normalized form.

    Unknown tokens are preserved, so an already-English query passes
    through unchanged.
    """

    if not query:

        return ""

    normalized = _tokenize(query)

    # ---- 1. Multi-word phrase replacement (longest first) ----
    for phrase, english in _MULTI:

        if phrase in normalized:

            normalized = normalized.replace(
                phrase,
                english
            )

    # ---- 2. Single-token replacement ----
    tokens = normalized.split()

    translated = []

    for token in tokens:

        translated.append(
            _SINGLE.get(token, token)
        )

    result = " ".join(translated)

    result = re.sub(r"\s+", " ", result).strip()

    return result



def analyze_translation(query):

    """
    Return translation plus debug info: which tokens changed and which
    were left untouched. Useful for the API response and for tuning the
    dictionary.
    """

    if not query:

        return {
            "original": "",
            "translated": "",
            "changed": [],
            "unchanged": [],
            "was_translated": False
        }

    normalized = _tokenize(query)

    # Apply multi-word replacements, tracking them.
    changed_phrases = []

    for phrase, english in _MULTI:

        if phrase in normalized:

            normalized = normalized.replace(phrase, english)

            changed_phrases.append((phrase, english))

    tokens = normalized.split()

    changed = []
    unchanged = []

    for token in tokens:

        if token in _SINGLE:

            changed.append((token, _SINGLE[token]))

        else:

            unchanged.append(token)

    translated = translate_query(query)

    return {
        "original": query.strip(),
        "normalized": _tokenize(query),
        "translated": translated,
        "multiword_matches": [
            {"roman": r, "english": e} for r, e in changed_phrases
        ],
        "single_matches": [
            {"roman": r, "english": e} for r, e in changed
        ],
        "unchanged_tokens": unchanged,
        "was_translated": translated.lower() != query.strip().lower()
    }



def dictionary_stats():

    """Return counts for reporting / admin endpoints."""

    return {
        "single_word_terms": len(_SINGLE),
        "multiword_phrases": len(_MULTI),
        "total_terms": len(_SINGLE) + len(_MULTI),
        "meets_objective_minimum": (
            (len(_SINGLE) + len(_MULTI)) >= 200
        )
    }
