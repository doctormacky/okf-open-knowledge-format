---
type: Playbook
title: Run the revenue computation
description: Runs the sanctioned Python computation and returns a receipt.
---

# Steps

1. Load [the computation contract](/computations/revenue.md).
2. Bind the declared `fiscal_year` parameter.
3. Run `/artifacts/revenue.py` without modification.
4. Return `fiscal_year`, `input_rows`, and `result`.
