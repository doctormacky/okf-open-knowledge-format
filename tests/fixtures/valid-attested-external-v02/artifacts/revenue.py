def compute(rows: list[dict], fiscal_year: int) -> int | float:
    return sum(
        row["amount"]
        for row in rows
        if row["status"] == "delivered"
        and row["fiscal_year"] == fiscal_year
    )
