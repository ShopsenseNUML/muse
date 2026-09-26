import os

from backend.services.csv_import_service import import_csv



BASE_DIR = os.path.dirname(
    os.path.dirname(
        os.path.abspath(__file__)
    )
)


CSV_PATH = os.path.join(
    BASE_DIR,
    "data",
    "imports",
    "products.csv"
)



if __name__ == "__main__":


    print(
        "CSV location:",
        CSV_PATH
    )


    if not os.path.exists(CSV_PATH):

        raise FileNotFoundError(
            f"CSV file not found: {CSV_PATH}"
        )


    total = import_csv(
        CSV_PATH
    )


    print(
        "\nTotal raw imported:",
        total
    )