import time



def log_search(
    start,
    count
):

    duration = (
        time.time()
        -
        start
    )


    print(
        f"""
SEARCH STATS

Results:
{count}

Time:
{duration:.4f}s

"""
    )