from pathlib import Path

from backend.services.product_import_service import (
    import_product_folder
)



def main():

    # Resolved from this file so the worker works from any working directory.
    folder = str(
        Path(__file__).resolve().parent.parent / "data" / "products"
    )


    print(
        "\n=============================="
    )

    print(
        "Starting product folder import"
    )

    print(
        "Folder:",
        folder
    )

    print(
        "==============================\n"
    )



    count = import_product_folder(
        folder
    )


    print(
        "\n=============================="
    )

    print(
        "Imported products:",
        count
    )

    print(
        "=============================="
    )



if __name__ == "__main__":

    main()