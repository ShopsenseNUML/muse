def classify_similarity(score):

    if score >= 0.95:
        return "Exact Match"

    if score >= 0.90:
        return "Very Similar"

    if score >= 0.80:
        return "Similar"

    if score >= 0.70:
        return "Related"

    return "Weak"