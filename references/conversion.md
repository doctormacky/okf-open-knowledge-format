# Converting and Migrating to OKF v0.2

Use this guide when migrating an OKF v0.1 bundle or converting another
knowledge source. Preserve information first; normalize only when the target
field can be populated truthfully.

## General Conversion Workflow

1. Inventory source files, metadata, links, attachments, and source identities.
2. Define the bundle root and target concept boundaries.
3. Map source metadata to OKF fields without inventing values.
4. Record conversion provenance with `generated` and `sources` when known.
5. Convert relationships to standard Markdown links.
6. Generate `index.md` files and an optional `log.md`.
7. Run `scripts/validate.sh <bundle>`.
8. Report fields, actors, timestamps, or sources that could not be resolved.

## Migrate OKF v0.1 to v0.2

### 1. Declare the version

If the root `index.md` declares a version, update only that value:

```yaml
---
okf_version: "0.2"
---
```

Do not add frontmatter to nested index files.

### 2. Replace `timestamp`

v0.2 supersedes `timestamp` with `generated.at` and an actor:

```yaml
# v0.1
timestamp: 2026-05-28T14:30:00Z

# v0.2
generated:
  by: process:legacy-import
  at: 2026-05-28T14:30:00Z
```

Use the real original actor when known. `process:legacy-import` is appropriate
only when that named process actually performed the import. If the actor is
unknown, retain the legacy `timestamp` and report the unresolved migration;
v0.2 consumers may use it as a fallback.

Do not use the migration time as the original content-change time. If the
migration itself meaningfully rewrites content, use its real time and actor and
preserve the original timestamp in an extension field only when the user wants
that history retained.

### 3. Replace `# Citations`

Convert each legacy citation into a `sources` entry:

```markdown
# v0.1 body

# Citations

[1] [Billing policy](https://example.com/billing)
```

```yaml
# v0.2 frontmatter
sources:
  - id: billing-policy
    resource: https://example.com/billing
    title: Billing policy
```

For a claim supported by that source:

```markdown
One-time setup fees are excluded.[^billing-policy]

[^billing-policy]: Billing policy
```

Use stable, descriptive, unique IDs. Do not infer which claim a citation
supports when the legacy document does not say. In that case, add the source to
frontmatter, keep the legacy citation section until review, and report the
ambiguity.

### 4. Add optional 0.2 families selectively

- Add `status` only when lifecycle state is known.
- Add `stale_after` only when an explicit review deadline exists.
- Add `verified` only for an actual check against a source or resource.
- Add source credibility signals only when measured or supplied.
- Do not turn ordinary code snippets into Attested Computations. Use that type
  only for a sanctioned contract with stable execution and verification
  semantics.

### 5. Validate compatibility

Confirm that:

- All timestamp-valued 0.2 fields have an explicit UTC offset.
- Every `sources` entry has `resource`.
- Every footnote used for source attribution has a matching `sources[].id`.
- `generated.by` and `verified[].by` use the actor convention.
- Only the root index carries `okf_version: "0.2"`.
- No legacy field was removed before its replacement was complete.

## Convert a Notion Export

Notion exports pages as Markdown and databases as Markdown plus CSV.

### Mapping

| Notion data | OKF v0.2 target |
| --- | --- |
| Type property | `type` |
| Page name | `title` and slugged filename |
| Summary property | `description` |
| Tags / multi-select | `tags` |
| Canonical asset URL | `resource` |
| Exported page URL | `sources[].resource` |
| Last edited time | `sources[].last_modified` |
| Conversion process | `generated.by` |
| Conversion time | `generated.at` |

### Procedure

1. Remove Notion UUID suffixes from filenames while keeping a mapping from old
   paths to new paths.
2. Convert properties to YAML frontmatter.
3. Add a source entry for the original page when its URL is available.
4. Convert Notion links to the renamed relative Markdown paths.
5. Preserve nested pages as subdirectories when the hierarchy is meaningful.
6. Remove export-only artifacts such as empty toggles and cover-image metadata.
7. Ask for `type` when it cannot be derived reliably.

Notion formulas and rollups are evaluated export artifacts, not portable
definitions. Preserve their displayed value only when useful, and do not model
them as Attested Computations unless the executable formula and verification
contract are actually available.

## Convert an Obsidian Vault

Obsidian content is close to OKF but may use syntax outside portable Markdown.

### Links and embeds

- `[[Note Name]]` -> `[Note Name](./note-name.md)`
- `[[Note Name|Display Text]]` -> `[Display Text](./note-name.md)`
- `[[Note Name#Heading]]` -> `[Note Name](./note-name.md#heading)`
- `![[image.png]]` -> `![](./image.png)`
- `![[Note Name]]` -> a link or explicitly inlined content

Keep a path-resolution map. Do not guess between duplicate note names; report
ambiguous wikilinks.

### Frontmatter

- Preserve all existing unknown keys.
- Ensure every concept has a non-empty `type`.
- Move inline `#tags` to `tags` only when they are actual tags rather than
  prose or headings.
- Map a genuine original creation/edit actor to `generated` when known.
- Turn external source metadata into `sources` and keyed footnotes.
- Treat MOC/index notes as `index.md` only if they are directory listings;
  otherwise retain them as ordinary concepts.

Dynamic Dataview queries do not become Attested Computations automatically.
Preserve them as examples or source text unless there is a sanctioned runtime,
declared parameters, executor receipt, and deterministic attester.

## Convert CSV or a Spreadsheet

Each row usually becomes one concept.

### Mapping

| Source column role | OKF target |
| --- | --- |
| Primary identifier / name | Slugged filename and `title` |
| Category / kind | `type` |
| Short summary | `description` |
| Labels | `tags` |
| Canonical asset URL | `resource` |
| Source row or sheet URL | `sources[].resource` |
| Source modified time | `sources[].last_modified` |
| Other stable values | Body table or domain-specific extension fields |

### Template

```markdown
---
type: Product
title: Example Product
description: Short source-backed description.
tags: [catalog]
generated:
  by: process:spreadsheet-import
  at: 2026-08-24T10:30:00Z
sources:
  - id: catalog-row
    resource: https://example.com/catalog#row-42
    title: Product catalog, row 42
---

# Details

| Field | Value |
| --- | --- |
| SKU | EXAMPLE-42 |
```

Use the real process identifier and time. Omit `generated` rather than copying
placeholder values.

### Edge cases

- Omit empty cells rather than writing empty YAML keys.
- Parse multi-value cells into a YAML list only when the delimiter is known.
- Put long text in the body, not frontmatter.
- Disambiguate duplicate filenames deterministically.
- Preserve row identifiers so regenerated concepts can be matched.
- Do not interpret calculated cells as attested computations without the
  calculation contract and deterministic verification path.

## Post-conversion Review

After structural validation, manually review:

- Whether each concept boundary makes sense to a human reader.
- Whether provenance points to the actual source rather than a nearby page.
- Whether claim footnotes join to the correct source IDs.
- Whether generated and verified actors describe real events.
- Whether deprecated or stale concepts are surfaced rather than silently used.
- Whether any executable resource was copied without an explicit trust review.
