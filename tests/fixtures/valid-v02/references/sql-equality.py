REQUIRED_RECEIPT_FIELDS = {"job_id", "executed_sql", "result"}


def attest(receipt: dict) -> bool:
    """Return whether the receipt contains the evidence required by the contract."""
    return REQUIRED_RECEIPT_FIELDS.issubset(receipt)
