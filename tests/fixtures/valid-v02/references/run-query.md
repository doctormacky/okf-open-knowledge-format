---
type: Playbook
title: Run the revenue query
description: Executes the sanctioned BigQuery computation with declared parameters.
---

# Steps

1. Load the computation without modifying its SQL.
2. Bind only the declared `fiscal_year` parameter.
3. Submit the query and return `job_id`, `executed_sql`, and `result`.
