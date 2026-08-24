---
type: Attested Computation
title: Revenue computation
description: Computes recognized revenue for a supplied fiscal year.
tags: [finance, revenue, attested]
status: stable
runtime: python
parameters:
  - { name: fiscal_year, type: integer, required: true }
computation: /artifacts/revenue.py
executor:
  resource: /runbooks/run-revenue.md
  receipt: [fiscal_year, input_rows, result]
attester:
  resource: /artifacts/attest.py
generated:
  by: human:finance-owner
  at: 2026-08-20T10:00:00Z
verified:
  by: human:finance-reviewer
  at: 2026-08-21T15:00:00Z
stale_after: 2026-11-20T10:00:00Z
sources:
  - id: revenue-policy
    resource: /policies/revenue.md
    title: Revenue recognition policy
---

# Contract

The external computation implements the revenue recognition
policy.[^revenue-policy]

[^revenue-policy]: Revenue recognition policy
