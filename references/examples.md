# OKF v0.2 Examples

These examples show the v0.2 fields only when the scenario supplies the
corresponding evidence. Optional metadata is intentionally not padded.

## 1. Analytics Bundle with Provenance

```text
ecommerce/
├── index.md
├── log.md
├── tables/
│   ├── index.md
│   └── orders.md
└── metrics/
    ├── index.md
    └── gross-revenue.md
```

### `index.md`

```markdown
---
okf_version: "0.2"
---

# E-commerce Analytics

* [Tables](./tables/) - Warehouse tables
* [Metrics](./metrics/) - Business metric definitions
```

### `tables/orders.md`

```markdown
---
type: BigQuery Table
title: Orders
description: One row per completed customer order.
resource: https://console.cloud.google.com/bigquery?p=acme&d=sales&t=orders
tags: [sales, orders]
status: stable
generated:
  by: process:bq-catalog-export
  at: 2026-08-20T04:00:00Z
verified:
  by: human:data-steward
  at: 2026-08-21T09:00:00Z
stale_after: 2026-09-20T04:00:00Z
sources:
  - id: warehouse-schema
    resource: https://docs.example.com/warehouse/orders
    title: Orders warehouse schema
    author: team:data-platform
    last_modified: 2026-08-18T11:30:00Z
---

# Schema

| Column | Type | Description |
| --- | --- | --- |
| `order_id` | STRING | Unique order identifier |
| `customer_id` | STRING | Customer identifier |
| `total_usd` | NUMERIC | Recognized order value in USD |
| `placed_at` | TIMESTAMP | Order submission time |

The schema is maintained in the warehouse documentation.[^warehouse-schema]

[^warehouse-schema]: Orders warehouse schema
```

### `metrics/gross-revenue.md`

```markdown
---
type: Metric
title: Gross Revenue
description: Total recognized order value before refunds.
tags: [revenue, finance, kpi]
status: draft
generated:
  by: human:finance-analyst
  at: 2026-08-21T14:00:00Z
sources:
  - id: revenue-policy
    resource: https://docs.example.com/finance/revenue-policy
    title: Revenue recognition policy
    author: team:finance
    last_modified: 2026-08-01T00:00:00Z
---

# Definition

Gross revenue is the sum of `total_usd` from
[orders](/tables/orders.md) for completed orders. Refunds are excluded from
this metric.[^revenue-policy]

[^revenue-policy]: Revenue recognition policy
```

This metric remains `draft` and has no `verified` field. Generation by a human
does not imply independent review.

## 2. Incident Playbook with Lifecycle

```text
incidents/
├── index.md
├── alerts/
│   ├── index.md
│   └── api-latency-p99.md
└── runbooks/
    ├── index.md
    └── escalate-incident.md
```

### `alerts/api-latency-p99.md`

````markdown
---
type: Alert
title: API latency P99 above two seconds
description: Fires when API P99 latency exceeds two seconds for five minutes.
tags: [api, latency, critical]
status: stable
generated:
  by: human:sre-owner
  at: 2026-08-01T09:00:00Z
verified:
  - by: process:monitoring-config-check
    at: 2026-08-22T02:00:00Z
stale_after: 2026-11-01T09:00:00Z
sources:
  - id: alert-config
    resource: https://monitoring.example.com/alerts/api-latency-p99
    title: Production alert configuration
    last_modified: 2026-07-31T18:00:00Z
---

# Trigger

```promql
histogram_quantile(
  0.99,
  rate(http_request_duration_seconds_bucket[5m])
) > 2
```

This expression mirrors the production alert configuration.[^alert-config]

# Response

Follow the [incident escalation runbook](/runbooks/escalate-incident.md) if
the alert is not resolved in ten minutes.

[^alert-config]: Production alert configuration
````

The trust tier is `machine-confirmed` because `verified` contains no
`human:` actor.

### Deprecated runbook

```yaml
type: Runbook
title: Legacy API rollback
status: deprecated
generated: { by: human:sre-owner, at: 2026-05-01T09:00:00Z }
```

A consumer should keep this concept addressable for existing links but should
prefer a current replacement. `deprecated` is not a deletion instruction.

## 3. Attested Computation

```text
finance/
├── index.md
├── metrics/
│   └── revenue.md
├── computations/
│   ├── index.md
│   └── revenue-ytd.md
└── references/
    ├── skills/
    │   └── run-on-bq.md
    └── attesters/
        └── sql-equality.py
```

### Narrative concept

```markdown
---
type: Metric
title: Year-to-date revenue
description: Recognized revenue from the start of the fiscal year.
tags: [finance, revenue]
status: stable
generated:
  by: human:finance-owner
  at: 2026-08-20T10:00:00Z
sources:
  - id: revenue-policy
    resource: /references/policies/revenue-recognition.md
    title: Revenue recognition policy
---

# Definition

Year-to-date revenue follows the revenue recognition policy.[^revenue-policy]
It is produced by the
[sanctioned computation](/computations/revenue-ytd.md).

[^revenue-policy]: Revenue recognition policy
```

### `computations/revenue-ytd.md`

````markdown
---
type: Attested Computation
title: Year-to-date revenue computation
description: Computes recognized revenue through an inclusive end date.
tags: [finance, revenue]
status: stable
runtime: bigquery
parameters:
  - name: fiscal_year
    type: integer
    required: true
  - name: end_date
    type: date
    required: true
executor:
  resource: /references/skills/run-on-bq.md
  receipt: [job_id, executed_sql, result]
attester:
  resource: /references/attesters/sql-equality.py
generated:
  by: human:finance-owner
  at: 2026-08-20T10:00:00Z
verified:
  by: human:finance-reviewer
  at: 2026-08-21T15:00:00Z
stale_after: 2026-11-20T10:00:00Z
sources:
  - id: revenue-policy
    resource: /references/policies/revenue-recognition.md
    title: Revenue recognition policy
---

# Computation

```sql
SELECT SUM(amount) AS revenue_ytd
FROM finance.recognized_revenue
WHERE fiscal_year = @fiscal_year
  AND recognized_at < TIMESTAMP(DATE_ADD(@end_date, INTERVAL 1 DAY))
```

The query implements the inclusive period defined by policy.[^revenue-policy]

[^revenue-policy]: Revenue recognition policy
````

The consumer:

1. Loads the declared runtime, parameters, and computation.
2. Accepts values only for `fiscal_year` and `end_date`.
3. Uses the executor to obtain the declared receipt fields.
4. Runs the deterministic attester against that receipt.
5. Refuses or warns on a failed attestation and surfaces the verdict.

The receipt and verdict are runtime artifacts; they are not written into the
bundle. Validating this document does not authorize running the query or the
attester.

## 4. External Computation File

For a long or shared computation, use a path and omit inline code:

```markdown
---
type: Attested Computation
title: Gross profit computation
runtime: dbt
parameters:
  - { name: fiscal_year, type: integer, required: true }
computation: /references/computations/gross-profit.sql
executor:
  resource: /references/skills/run-dbt.md
  receipt: [run_id, compiled_sql, result]
attester:
  resource: /references/attesters/dbt-binding.py
---

# Gross Profit Computation

This contract uses the reviewed computation stored at `computation`.
```

Do not include a second computation code block. The agent may bind
`fiscal_year` but may not modify `gross-profit.sql` as part of execution.

## 5. Trust and Freshness Interpretation

Given:

```yaml
status: stable
verified:
  - { by: process:nightly-check, at: 2026-08-22T02:00:00Z }
  - { by: human:data-owner, at: 2026-08-20T09:00:00Z }
stale_after: 2026-09-01T00:00:00Z
```

- Trust tier: `human-reviewed` because at least one verifier is human.
- Fresh before `2026-09-01T00:00:00Z`.
- Stale at or after that instant.
- Still structurally conformant when stale; freshness affects consumption,
  not file validity.
