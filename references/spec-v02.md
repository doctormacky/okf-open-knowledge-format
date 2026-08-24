# OKF v0.2 Implementation Reference

This is a task-oriented reference for agents producing or consuming Open
Knowledge Format v0.2. The normative source is the official
[GoogleCloudPlatform specification](https://github.com/GoogleCloudPlatform/open-knowledge-format/blob/ad30107c31c06aec8a7d5636e0d1058118604e6f/SPEC.md),
pinned here to commit `ad30107c31c06aec8a7d5636e0d1058118604e6f`.

When this summary and the pinned specification differ, follow the pinned
specification.

## 1. Bundle and Concept Model

An OKF bundle is a directory tree of UTF-8 Markdown files.

- Each non-reserved `.md` file is one concept.
- A concept ID is its bundle-relative path without `.md`.
- `index.md` and `log.md` are reserved at every directory level.
- A concept consists of YAML frontmatter followed by a Markdown body.
- A bundle can be a repository, archive, or subdirectory.

Example:

```text
bundle/
├── index.md
├── log.md
├── metrics/
│   ├── index.md
│   └── revenue.md
└── computations/
    ├── index.md
    └── revenue-ytd.md
```

## 2. Concept Frontmatter

### Core and display fields

```yaml
---
type: Metric
title: Revenue
description: Recognized revenue for a fiscal year.
resource: https://example.com/catalog/revenue
tags: [finance, revenue]
---
```

| Field | Requirement | Meaning |
| --- | --- | --- |
| `type` | Required | Free-form concept kind |
| `title` | Recommended | Human-readable display name |
| `description` | Recommended | One-sentence summary |
| `resource` | Optional | URI for the underlying asset |
| `tags` | Optional | Cross-cutting labels |

`type` is the only always-required key. Type values are not centrally
registered. Consumers must tolerate unknown types and additional frontmatter
keys, and should preserve unknown keys when round-tripping.

### Timestamp rule

Every timestamp-valued OKF field is an ISO 8601 datetime with an explicit UTC
offset:

```yaml
at: 2026-08-24T10:30:00Z
last_modified: 2026-08-24T18:30:00+08:00
```

A date-only value such as `2026-08-24` is not a valid OKF timestamp. Date
headings in `log.md` are not frontmatter timestamps and remain `YYYY-MM-DD`.

Timestamp-valued fields are:

- `generated.at`
- `verified[].at`
- `stale_after`
- `sources[].last_modified`
- `usage_window.from` and `usage_window.to`

## 3. Provenance

### `sources`

`sources` records the material a concept derives from.

```yaml
sources:
  - id: revenue-policy
    resource: https://example.com/revenue-policy
    title: Revenue recognition policy
    author: team:finance
    usage_count: 5000
    last_modified: 2026-08-01T00:00:00Z
usage_window:
  from: 2026-08-01T00:00:00Z
  to: 2026-08-31T00:00:00Z
```

Each source entry has:

| Field | Requirement | Meaning |
| --- | --- | --- |
| `resource` | Required within an entry | URL, bundle path, relative path, or scope descriptor |
| `id` | Optional; recommended for cited claims | Stable footnote join key |
| `title` | Optional | Human-readable source label |
| `author` | Optional | Source producer |
| `usage_count` | Optional | Coarse liveness/adoption signal |
| `last_modified` | Optional | Time the source changed |
| `usage_window` | Optional override | Window for that source's usage count |

A top-level `usage_window` applies to source entries unless an entry overrides
it. Usage count is a signal, not a portable score. Do not compare unlike
activities as precise rankings.

Sources may point to other concepts. Follow those links for deeper lineage; v0.2
does not define a separate `derived_from` field.

### Claim attribution

Join claims to sources with stable Markdown footnote labels:

```markdown
Revenue excludes pass-through taxes.[^revenue-policy]

[^revenue-policy]: Revenue recognition policy
```

The label `revenue-policy` resolves to `sources[].id`. Consumers use the ID,
not the footnote prose, as the join key.

The v0.1 `# Citations` list is legacy. A v0.2 producer should use `sources`,
while a consumer may still parse the old section as a fallback.

## 4. Production, Verification, and Trust

### `generated`

`generated` records who or what produced the current content.

```yaml
generated:
  by: reference-agent/gemini-2.5-pro
  at: 2026-08-20T22:53:05Z
```

`generated.by` is required whenever `generated` is present.
`generated.at` records the last meaningful content change.

### `verified`

`verified` records confirmation against sources or the underlying resource:

```yaml
verified:
  - by: human:reviewer-42
    at: 2026-08-21T09:00:00Z
  - by: process:finance-nightly
    at: 2026-08-22T02:00:00Z
```

A single event may be a bare mapping:

```yaml
verified: { by: human:reviewer-42, at: 2026-08-21T09:00:00Z }
```

Consumers must normalize that mapping to a one-element list. Production and
verification are independent: editing content does not re-verify it, and a new
verification does not imply the content was regenerated.

### Actor convention

- Agent or tool: `<producer>/<version>`
- Person: `human:<id>`
- Automated process: `process:<id>`

Use `human:` for hand-authored or human-confirmed content because trust-tier
derivation depends on that prefix.

### Derived trust tiers

| `verified` state | Trust tier |
| --- | --- |
| Absent | `unverified` |
| Only non-human actors | `machine-confirmed` |
| At least one `human:` actor | `human-reviewed` |

These tiers are advisory signals, not permissions, authorization, or access
control.

## 5. Lifecycle

### `status`

Allowed values:

- `draft`: incomplete or not reviewed.
- `stable`: ready for consumption.
- `deprecated`: retained for history and links, but not current.

Absent `status` means `stable`.

### `stale_after`

```yaml
stale_after: 2026-09-23T00:00:00Z
```

A concept is stale when `now >= stale_after`. It is an absolute instant, not a
relative TTL. Ignore a value that lacks an explicit UTC offset when deriving
freshness.

## 6. Links and Paths

Standard Markdown links express directed, untyped relationships:

```markdown
[Customers](/tables/customers.md)
[Neighbor](./neighbor.md)
```

Bundle-relative links beginning with `/` are preferred. Broken links are
allowed and do not make a bundle nonconformant.

Path-valued fields accept absolute URLs, bundle-relative paths, or relative
paths:

- `resource`
- `sources[].resource`, except when it is a scope descriptor
- `computation`
- `executor.resource`
- `attester.resource`

A `references/` directory is conventional for mirrored source material,
execution instructions, and attester code; it is not required.

## 7. Reserved Files

### `index.md`

An index may appear in any directory and normally has no frontmatter. The
bundle-root index may declare the target version:

```markdown
---
okf_version: "0.2"
---

# Finance

* [Metrics](./metrics/) - Business definitions
* [Computations](./computations/) - Sanctioned computations
```

Use headings to group entries. Include linked concept descriptions when
available.

### `log.md`

A log has no frontmatter. Entries are grouped newest first:

```markdown
# Update Log

## 2026-08-24
* **Update**: Migrated provenance to `sources`.

## 2026-08-20
* **Creation**: Initialized the bundle.
```

Date headings must use `YYYY-MM-DD`. The bold leading action is conventional,
not required.

## 8. Attested Computation

An Attested Computation records a sanctioned way to compute a value and enough
information for a consumer to verify a run.

````markdown
---
type: Attested Computation
title: Revenue for fiscal year
description: Recognized revenue for a fiscal year.
runtime: bigquery
parameters:
  - name: year
    type: integer
    required: true
executor:
  resource: /references/skills/run-on-bq.md
  receipt: [job_id, executed_sql, result]
attester:
  resource: /references/attesters/sql-equality.py
generated:
  by: human:finance-owner
  at: 2026-08-20T22:53:05Z
---

# Computation

```sql
SELECT SUM(amount) AS revenue
FROM finance.recognized_revenue
WHERE fiscal_year = @year
```
````

Contract rules:

- `type` is exactly `Attested Computation`.
- `runtime` is required and defines parameter binding semantics.
- Each `parameters` entry declares `name`, `type`, and `required`.
- Provide the computation either as one inline code block under
  `# Computation` or with the `computation` path, not both.
- `executor.resource` identifies run instructions or code.
- `executor.receipt` declares the evidence a run must return.
- `attester.resource` identifies deterministic, non-LLM verification code.
- The agent may supply only declared parameter values. It must not author or
  alter the sanctioned computation.

The runtime receipt and verdict are not stored in the bundle. `verified` checks
the definition at document level; attestation checks one execution. Neither
substitutes for the other.

Reading or validating this contract does not authorize execution.

## 9. Conformance

A bundle conforms to OKF v0.2 when:

1. Every non-reserved `.md` file has parseable YAML frontmatter.
2. Every concept frontmatter has a non-empty `type`.
3. Every present `index.md` and `log.md` follows its reserved structure.

When optional v0.2 families are present, producers should follow their field
contracts. Consumers:

- Must normalize a bare `verified` mapping to a one-item list.
- Must not reject a concept because an optional family is absent.
- Should derive trust and freshness only from the specified fields.
- Should surface a failed attestation rather than silently discarding it.

Do not reject a bundle solely for:

- Missing optional fields.
- Unknown types.
- Unknown extension keys.
- Broken links.
- Missing index files.

## 10. Versioning and v0.1 Migration

OKF 0.2 supersedes 0.1. It is mostly additive, with two deliberate field
changes:

| v0.1 | v0.2 | Compatibility |
| --- | --- | --- |
| `timestamp` | `generated.at` plus `generated.by` | Consumer may fall back to `timestamp` |
| Body `# Citations` | Frontmatter `sources` plus keyed footnotes | Consumer may parse the old list |

Additions in 0.2:

- `sources`, per-source credibility signals, and `usage_window`
- `generated` and `verified`
- `status` and `stale_after`
- Actor conventions
- `Attested Computation` with `runtime`, `parameters`, `computation`,
  `executor`, and `attester`
- Conventional `# Computation` heading

Bundle structure, reserved filenames, `type`, the display fields, cross-links,
index files, log files, and permissive consumption remain unchanged.
