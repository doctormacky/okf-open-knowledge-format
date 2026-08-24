---
type: Attested Computation
title: Revenue computation
description: Computes recognized revenue for a fiscal year.
runtime: bigquery
parameters:
  - name: fiscal_year
    type: integer
    required: true
executor:
  resource: /references/run-query.md
  receipt: [job_id, executed_sql, result]
attester:
  resource: /references/sql-equality.py
---

# Computation

```sql
SELECT SUM(amount)
FROM finance.recognized_revenue
WHERE fiscal_year = @fiscal_year
```
