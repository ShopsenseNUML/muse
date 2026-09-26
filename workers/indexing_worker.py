from backend.services.indexing_service import (
    rebuild_vector_index
)


if __name__ == "__main__":

    print(
        "Building vector index..."
    )

    rebuild_vector_index()

    print(
        "Done"
    )