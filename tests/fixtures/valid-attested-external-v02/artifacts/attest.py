from revenue import compute


def attest(receipt: dict, rows: list[dict]) -> bool:
    expected = compute(rows, receipt["fiscal_year"])
    return (
        receipt["input_rows"] == len(rows)
        and receipt["result"] == expected
    )
