from backend.services.product_import_service import (
    import_product_folder
)



def main():

    folder = "data/products"


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