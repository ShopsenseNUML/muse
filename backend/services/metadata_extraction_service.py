import re



KNOWN_BRANDS = [

    "Samsung",
    "Apple",
    "Nike",
    "Adidas",
    "Xiaomi",
    "Huawei",
    "OnePlus",
    "Garmin",
    "Amazfit",
    "Realme",
    "Sony"

]



CATEGORY_KEYWORDS = {


    "watch":
    "Smart Watch",


    "galaxy watch":
    "Smart Watch",


    "apple watch":
    "Smart Watch",


    "ultraboost":
    "Shoes",


    "air max":
    "Shoes",


    "iphone":
    "Mobile",


    "laptop":
    "Laptop",


    "camera":
    "Camera"

}



def clean_title(filename):


    name = filename.replace(
        ".jpg",
        ""
    ).replace(
        ".png",
        ""
    ).replace(
        ".webp",
        ""
    )


    name = name.replace(
        "_",
        " "
    )


    return name.strip()



def extract_brand(title):


    title_lower = title.lower()


    for brand in KNOWN_BRANDS:


        if brand.lower() in title_lower:

            return brand


    return "Unknown"



def extract_category(title):


    title_lower = title.lower()


    for key, value in CATEGORY_KEYWORDS.items():


        if key in title_lower:

            return value


    return "Unknown"



def generate_description(
    title,
    brand,
    category
):


    return (
        f"{brand} {category} product. "
        f"{title}. "
        "Available for visual similarity search."
    )



def extract_metadata(filename):


    title = clean_title(
        filename
    )


    brand = extract_brand(
        title
    )


    category = extract_category(
        title
    )


    return {


        "title": title,


        "brand": brand,


        "category": category,


        "description":
        generate_description(
            title,
            brand,
            category
        )

    }