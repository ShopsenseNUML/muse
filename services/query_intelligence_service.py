import re


from backend.services.roman_urdu_service import (
    analyze_translation,
    translate_query
)


KNOWN_BRANDS = [

    "samsung",
    "apple",
    "adidas",
    "nike",
    "xiaomi",
    "huawei",
    "sony",
    "oppo",
    "realme",
    "oneplus"

]


KNOWN_CATEGORIES = {

    "watch": "Smart Watch",
    "smartwatch": "Smart Watch",

    "shoe": "Shoes",
    "shoes": "Shoes",
    "sneaker": "Shoes",

    "phone": "Mobile",
    "mobile": "Mobile",

    "laptop": "Laptop",

    "camera": "Camera",

    "keyboard": "Keyboard",

    "mouse": "Mouse"
}


def normalize_query(query):

    return query.lower().strip()


def extract_brand(query):

    query = normalize_query(query)

    for brand in KNOWN_BRANDS:

        if brand in query:

            return brand.title()

    return None


def extract_category(query):

    query = normalize_query(query)

    for keyword, category in KNOWN_CATEGORIES.items():

        if keyword in query:

            return category

    return None


def extract_price_limit(query):

    query = normalize_query(query)

    patterns = [

        r"under\s+(\d+)",

        r"below\s+(\d+)",

        r"less than\s+(\d+)",

        r"max\s+(\d+)"

    ]

    for pattern in patterns:

        match = re.search(
            pattern,
            query
        )

        if match:

            return float(
                match.group(1)
            )

    return None


def extract_keywords(query):

    query = normalize_query(query)


    words = query.split()


    stopwords = {

        "find",
        "show",
        "similar",
        "under",
        "below",
        "less",
        "than",
        "max",
        "with",
        "the",
        "a",
        "an",

    }


    keywords = []


    for word in words:


        # remove numbers
        if word.isdigit():
            continue


        if word not in stopwords:

            keywords.append(word)



    return keywords


def analyze_query(query):

    # -----------------------------------------
    # Roman Urdu -> English translation first,
    # so brand/category/price extraction runs on
    # the normalized English form. Unknown tokens
    # pass through unchanged (already English).
    # -----------------------------------------
    translation = analyze_translation(
        query
    )

    english_query = translation["translated"]

    return {

        "original_query":
        query,

        "translated_query":
        english_query,

        "translation":
        translation,

        "brand":
        extract_brand(english_query),

        "category":
        extract_category(english_query),

        "max_price":
        extract_price_limit(english_query),

        "keywords":
        extract_keywords(english_query)

    }