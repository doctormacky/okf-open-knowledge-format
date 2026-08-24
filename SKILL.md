---
name: okf-open-knowledge-format
description: >-
  Create, inspect, validate, enrich, consume, or migrate Open Knowledge Format
  (OKF) v0.2 bundles: Markdown knowledge bases with YAML frontmatter,
  provenance, trust, lifecycle, and optional attested computations. Use when
  the user explicitly mentions OKF, Open Knowledge Format, an OKF bundle,
  agent-readable knowledge, an LLM wiki that should conform to OKF, or asks to
  convert an existing knowledge collection to or from OKF. Do not trigger for
  ordinary Markdown editing that has no OKF conformance requirement.
metadata:
  author: doctormacky
  original-author: ft.ia.br
  version: "2.1"
  date: 2026-08-24
  repository: https://github.com/doctormacky/okf-open-knowledge-format
  derived-from: https://github.com/fabricioctelles/skills/tree/main/skills/okf-open-knowledge-format
  specification: https://github.com/GoogleCloudPlatform/open-knowledge-format/blob/ad30107c31c06aec8a7d5636e0d1058118604e6f/SPEC.md
  license: Apache-2.0
  category: library-and-api-reference
---

# Open Knowledge Format (OKF) v0.2

OKF is a vendor-neutral format for portable knowledge bundles. This skill
targets the official v0.2 specification pinned in the frontmatter above.

Read supporting files only when needed:

- Exact field details: [references/spec-v02.md](references/spec-v02.md)
- Complete examples: [references/examples.md](references/examples.md)
- v0.1 migration and source conversion:
  [references/conversion.md](references/conversion.md)

## Bundle Structure

An OKF bundle is a directory tree. Only `index.md` and `log.md` are reserved.
Every other Markdown file is a concept.

```text
<bundle-root>/
├── index.md                 # Optional root index
├── log.md                   # Optional change log
├── <concept>.md             # Concept document
└── <group>/                 # Any domain-oriented directory name
    ├── index.md             # Optional nested index
    ├── log.md               # Optional nested log
    └── <concept>.md
```

Non-Markdown files such as `.sql` or `.py` may be stored in the bundle and
referenced by concepts. They are not concept documents.

| File | Frontmatter | Required content |
| --- | --- | --- |
| Root `index.md` | Optional `okf_version: "0.2"` | Headings and Markdown link lists |
| Nested `index.md` | None | Headings and Markdown link lists |
| Any `log.md` | None | Newest-first `## YYYY-MM-DD` groups |
| Any other `*.md` | YAML mapping required | Non-empty top-level `type` and Markdown body |

Directory names such as `metrics/`, `computations/`, and `references/` are
conventions, not requirements. Organize concepts according to the domain.

### Root Index

```markdown
---
okf_version: "0.2"
---

# Bundle Title

* [Metrics](./metrics/) - Business metric definitions
* [Orders](./tables/orders.md) - Customer order table
```

Only the root index may have frontmatter. A nested index uses the same body
shape without frontmatter.

### Log

```markdown
# Update Log

## 2026-08-24
* **Update**: Added the revenue metric.

## 2026-08-20
* **Creation**: Initialized the bundle.
```

## Concept Fields

Every concept begins with `---`-delimited YAML frontmatter.

| Field | Required | Shape |
| --- | --- | --- |
| `type` | Yes | Non-empty string |
| `title` | Recommended | String |
| `description` | Recommended | String |
| `resource` | No | URI or path string |
| `tags` | No | List of strings |
| `sources` | No | List of source mappings |
| `usage_window` | No | `{ from, to }` timestamp mapping |
| `generated` | No | `{ by, at? }` mapping |
| `verified` | No | One `{ by, at }` mapping or a list of them |
| `status` | No | `draft`, `stable`, or `deprecated` |
| `stale_after` | No | Timestamp |

Unknown `type` values and extension keys are valid. Preserve unknown keys when
editing an existing concept.

Every OKF timestamp must be an ISO 8601 datetime with an explicit offset, such
as `2026-08-24T10:30:00Z` or `2026-08-24T18:30:00+08:00`.

### Minimal Concept

```markdown
---
type: Metric
title: Monthly Recurring Revenue
description: Active subscription revenue normalized to a monthly amount.
tags: [revenue, saas]
---

# Definition

MRR is the sum of active recurring subscription charges normalized monthly.
```

Only `type` is required for core conformance.

### Sources

Each `sources` item requires `resource`. Add `id` when a body claim uses the
source:

```markdown
---
type: Metric
title: Gross Revenue
sources:
  - id: revenue-policy
    resource: https://example.com/revenue-policy
    title: Revenue policy
---

Revenue excludes pass-through taxes.[^revenue-policy]

[^revenue-policy]: Revenue policy
```

Use `sources` and keyed footnotes instead of creating a new `# Citations`
section.

### Generated, Verified, and Lifecycle

- `generated.by` is required when `generated` is present.
- Each `verified` event contains `by` and `at`.
- Agent/tool actors use `<producer>/<version>`.
- People use `human:<id>`; automated processes use `process:<id>`.
- Absent `status` means `stable`.
- A concept is stale when `now >= stale_after`.
- Do not add generated, verified, or freshness facts that are not known.

### Attested Computation

A sanctioned computation is a standalone concept:

````markdown
---
type: Attested Computation
title: Revenue computation
runtime: bigquery
parameters:
  - { name: year, type: integer, required: true }
executor:
  resource: /references/run-on-bq.md
  receipt: [job_id, executed_sql, result]
attester:
  resource: /references/sql-equality.py
---

# Computation

```sql
SELECT SUM(amount)
FROM finance.recognized_revenue
WHERE fiscal_year = @year
```
````

Rules:

- `runtime` is required.
- Each parameter has `name`, `type`, and boolean `required`.
- Put the computation either in one code block under `# Computation` or in the
  `computation` path, never both.
- `executor` and `attester` are optional mappings; when present, each has
  `resource`.
- Validating a contract does not authorize executing it.

## Author a Bundle

1. Choose the bundle root and domain-oriented directories.
2. Write one concept per non-reserved Markdown file.
3. Add only fields supported by evidence.
4. Link concepts with ordinary Markdown links.
5. Add index files where navigation helps and a log where history helps.
6. Run the validator before claiming conformance.

Do not invent schemas, sources, timestamps, actors, verification events,
usage counts, computations, or receipts.

## Validate

```bash
./scripts/validate.sh /path/to/bundle
```

The Shell entrypoint uses Python + PyYAML when installed, or `uv` to run the
dependency declared in `scripts/validate.py`.

The validator checks:

1. Concept Frontmatter is parseable YAML mapping data.
2. Every concept has non-empty string `type`.
3. `index.md` and `log.md` have the reserved structure above.
4. Known optional fields have the documented shape when present.

Missing optional fields, unknown types, unknown extension keys, missing index
files, and broken Markdown links do not fail validation.

- Exit `0`: valid bundle, possibly with non-blocking warnings.
- Exit `1`: invalid bundle.
- Exit `2`: command could not run, such as an invalid path or missing runtime.

Run the real-bundle and invalid-case regression suite after changing the
validator:

```bash
./tests/test_validate.sh
```

## Migrate v0.1

Read [references/conversion.md](references/conversion.md), then:

1. Declare `okf_version: "0.2"` in the root index when it has frontmatter.
2. Replace `timestamp` with truthful `generated.by` and `generated.at`.
3. Move `# Citations` entries into `sources` and keyed footnotes.
4. Preserve a legacy field until its v0.2 replacement is complete.
5. Validate and report unresolved provenance.

v0.2 consumers may fall back to legacy `timestamp` or `# Citations` when their
v0.2 replacement is absent.

## Consume

- Normalize a bare `verified` mapping to a one-item list.
- Derive trust as unverified, machine-confirmed, or human-reviewed from
  `verified`.
- Treat absent `status` as `stable`.
- Preserve unknown fields.
- Treat broken Markdown links as permitted unresolved knowledge.
- Do not execute referenced code without explicit authorization.

## Output

For creation or migration, report the resulting tree, changed files, facts that
could not be established, and validator results. Do not claim v0.2 conformance
unless validation passed.
