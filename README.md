<div align="center">

# OKF Open Knowledge Format

**An AI-agent skill for creating, validating, enriching, and converting Open Knowledge Format bundles.**

**用于创建、校验、丰富和转换开放知识格式（OKF）知识包的 AI Agent Skill。**

[English](#english) | [简体中文](#简体中文)

![OKF Spec](https://img.shields.io/badge/OKF-v0.2-2563eb)
![Skill Version](https://img.shields.io/badge/Skill-v2.0-0f766e)
[![License](https://img.shields.io/badge/License-Apache--2.0-d97706)](https://github.com/fabricioctelles/skills/blob/main/LICENSE)

</div>

> [!IMPORTANT]
> **Provenance / 来源说明**
>
> The original `v0.1` baseline was reproduced without changes from
> [`fabricioctelles/skills/skills/okf-open-knowledge-format`](https://github.com/fabricioctelles/skills/tree/main/skills/okf-open-knowledge-format).
> That baseline matched upstream commit
> [`8d4f71a`](https://github.com/fabricioctelles/skills/commit/8d4f71a188a81855ad96b11254b4d777462baca9)
> byte for byte. The current `v0.2` adaptation is maintained in this repository
> and targets the official GoogleCloudPlatform OKF 0.2 specification at
> [`ad30107`](https://github.com/GoogleCloudPlatform/open-knowledge-format/blob/ad30107c31c06aec8a7d5636e0d1058118604e6f/SPEC.md);
> it is no longer an unchanged upstream mirror.
>
> 本仓库最初的 `v0.1` 基线原样来自
> [`fabricioctelles/skills/skills/okf-open-knowledge-format`](https://github.com/fabricioctelles/skills/tree/main/skills/okf-open-knowledge-format)，
> 当时 5 个 Skill 文件与上游提交
> [`8d4f71a`](https://github.com/fabricioctelles/skills/commit/8d4f71a188a81855ad96b11254b4d777462baca9)
> 逐字节一致。当前 `v0.2` 改造由本仓库维护，并固定适配 GoogleCloudPlatform
> 官方 OKF 0.2 规范提交
> [`ad30107`](https://github.com/GoogleCloudPlatform/open-knowledge-format/blob/ad30107c31c06aec8a7d5636e0d1058118604e6f/SPEC.md)，
> 因此已不再是上游文件的原样镜像。

---

## English

### Overview

Open Knowledge Format (OKF) is a vendor-neutral, human- and agent-readable
format for representing organizational knowledge as Markdown files with YAML
frontmatter. An OKF knowledge bundle is simply a directory tree: it requires no
SDK, central registry, or proprietary platform.

This repository packages an AI-agent skill that teaches compatible agents how
to create, validate, enrich, consume, migrate, and convert bundles following
the official OKF v0.2 specification.

### What This Skill Does

- Creates conformant OKF bundles and concept documents.
- Validates core conformance and selected OKF v0.2 field contracts.
- Records provenance, trust, freshness, lifecycle, and claim attribution.
- Authors and reviews optional Attested Computation contracts.
- Migrates v0.1 `timestamp` and `# Citations` conventions to v0.2.
- Converts Notion exports, Obsidian vaults, CSV files, and spreadsheets to OKF.
- Preserves producer-defined metadata and tolerates unknown concept types.

### Repository Structure

```text
.
├── SKILL.md                   # Agent instructions and operating rules
├── README.md                  # Bilingual project documentation
├── references/
│   ├── conversion.md         # Source-to-OKF conversion guides
│   ├── examples.md           # Complete example bundles
│   └── spec-v02.md           # Pinned OKF v0.2 implementation reference
├── scripts/
│   └── validate.sh           # Lightweight OKF conformance validator
└── tests/
    ├── fixtures/             # Valid, invalid, and legacy bundles
    └── test_validate.sh      # Validator regression tests
```

### Installation

Clone this repository into the skill directory scanned by your agent client.
Common locations include:

```bash
# Codex
git clone https://github.com/doctormacky/okf-open-knowledge-format.git \
  ~/.codex/skills/okf-open-knowledge-format

# Claude Code
git clone https://github.com/doctormacky/okf-open-knowledge-format.git \
  ~/.claude/skills/okf-open-knowledge-format
```

For other compatible agents, place the repository in that client's configured
skills directory. Start a new agent session after installation if the skill is
not detected immediately.

### Usage

Once installed, ask the agent to work with OKF in natural language. For
example:

```text
Create an OKF bundle for our SaaS metrics.
Validate this directory against the OKF v0.2 specification.
Convert this Obsidian vault into an OKF knowledge bundle.
Migrate this OKF v0.1 bundle to v0.2 without losing provenance.
Review this Attested Computation contract without executing it.
```

To run the bundled lightweight validator directly:

```bash
./scripts/validate.sh /path/to/your/bundle
```

The validator checks the three core conformance rules:

1. Every non-reserved Markdown file has YAML frontmatter.
2. Every concept has a non-empty `type` field.
3. Reserved `index.md` and `log.md` files follow their structural rules.

Existing OKF linters and profile manifests can provide additional checks, but
v0.1-era tooling should not be assumed to validate the new v0.2 field families.

### OKF at a Glance

A minimal OKF concept looks like this:

```markdown
---
type: Metric
title: Monthly Recurring Revenue
description: Active subscription revenue normalized to a monthly amount.
tags: [revenue, saas]
status: draft
generated:
  by: human:analyst
  at: 2026-08-24T10:30:00Z
---

# Monthly Recurring Revenue

The sum of all active subscriptions normalized to a monthly amount.
```

Only `type` is always required. OKF v0.2 adds optional `sources`, `generated`,
`verified`, `status`, `stale_after`, and Attested Computation fields. Producers
may add custom fields, and consumers should preserve fields they do not
recognize.

### Documentation

| Document | Purpose |
| --- | --- |
| [`SKILL.md`](./SKILL.md) | Complete agent workflow and guardrails |
| [`references/spec-v02.md`](./references/spec-v02.md) | Pinned OKF v0.2 implementation reference |
| [`references/examples.md`](./references/examples.md) | Provenance, lifecycle, and attestation examples |
| [`references/conversion.md`](./references/conversion.md) | v0.1 migration and source conversion guides |
| [`scripts/validate.sh`](./scripts/validate.sh) | Lightweight v0.2 command-line validator |

### Version and Provenance

| Item | Value |
| --- | --- |
| Current OKF target | `v0.2` |
| Skill metadata version | `2.0` |
| Official specification | [`ad30107`](https://github.com/GoogleCloudPlatform/open-knowledge-format/blob/ad30107c31c06aec8a7d5636e0d1058118604e6f/SPEC.md) |
| Original source | [`fabricioctelles/skills`](https://github.com/fabricioctelles/skills/tree/main/skills/okf-open-knowledge-format) |
| Unmodified v0.1 baseline | [`8d4f71a`](https://github.com/fabricioctelles/skills/commit/8d4f71a188a81855ad96b11254b4d777462baca9) |

### License

The upstream project and the skill metadata identify the work as licensed under
the [Apache License 2.0](https://github.com/fabricioctelles/skills/blob/main/LICENSE).
Please retain the original attribution and applicable license notices when
redistributing it.

---

## 简体中文

### 项目简介

开放知识格式（Open Knowledge Format，OKF）是一种厂商中立、同时面向人类和
AI Agent 的组织知识表示格式。它使用带 YAML Frontmatter 的 Markdown 文件组织
知识；一个 OKF 知识包就是一棵目录树，不依赖 SDK、中心化注册服务或专有平台。

本仓库提供一个 AI Agent Skill，指导兼容的 Agent 按照官方 OKF v0.2 规范创建、
校验、丰富、消费、迁移和转换 OKF 知识包。

### 主要能力

- 创建符合规范的 OKF 知识包和概念文档。
- 校验核心合规规则和部分 OKF v0.2 字段契约。
- 记录来源、信任、新鲜度、生命周期和声明级引用。
- 创建和审查可选的 Attested Computation 契约。
- 将 v0.1 的 `timestamp` 和 `# Citations` 迁移到 v0.2。
- 将 Notion 导出、Obsidian Vault、CSV 和电子表格转换为 OKF。
- 保留生产方自定义元数据，并兼容未知的概念类型。

### 仓库结构

```text
.
├── SKILL.md                   # Agent 指令与执行规则
├── README.md                  # 中英文项目说明
├── references/
│   ├── conversion.md         # 各类数据源到 OKF 的转换指南
│   ├── examples.md           # 完整知识包示例
│   └── spec-v02.md           # 固定版本的 OKF v0.2 实施参考
├── scripts/
│   └── validate.sh           # 轻量级 OKF 合规校验脚本
└── tests/
    ├── fixtures/             # 合法、非法和旧版知识包
    └── test_validate.sh      # 校验器回归测试
```

### 安装

将本仓库克隆到 Agent 客户端能够扫描到的 Skill 目录。常见路径如下：

```bash
# Codex
git clone https://github.com/doctormacky/okf-open-knowledge-format.git \
  ~/.codex/skills/okf-open-knowledge-format

# Claude Code
git clone https://github.com/doctormacky/okf-open-knowledge-format.git \
  ~/.claude/skills/okf-open-knowledge-format
```

其他兼容 Agent 请使用对应客户端配置的 Skill 目录。如果安装后没有立即识别，
请新建一个 Agent 会话。

### 使用方式

安装后，可以直接用自然语言让 Agent 处理 OKF 任务，例如：

```text
为我们的 SaaS 指标创建一个 OKF 知识包。
按照 OKF v0.2 规范校验这个目录。
将这个 Obsidian Vault 转换为 OKF 知识包。
在不丢失来源信息的前提下，将这个 OKF v0.1 知识包迁移到 v0.2。
审查这个 Attested Computation 契约，但不要执行它。
```

也可以直接运行仓库内置的轻量级校验器：

```bash
./scripts/validate.sh /path/to/your/bundle
```

该脚本检查 3 条核心合规规则：

1. 每个非保留 Markdown 文件都包含 YAML Frontmatter。
2. 每个概念都包含非空的 `type` 字段。
3. 保留文件 `index.md` 和 `log.md` 符合各自的结构规则。

已有 OKF Linter 和 Profile Manifest 可以提供额外检查，但不能默认旧版工具已经
覆盖 v0.2 新增的字段族。

### OKF 最小示例

```markdown
---
type: Metric
title: Monthly Recurring Revenue
description: Active subscription revenue normalized to a monthly amount.
tags: [revenue, saas]
status: draft
generated:
  by: human:analyst
  at: 2026-08-24T10:30:00Z
---

# Monthly Recurring Revenue

The sum of all active subscriptions normalized to a monthly amount.
```

只有 `type` 始终是必填字段。OKF v0.2 新增了可选的 `sources`、`generated`、
`verified`、`status`、`stale_after` 和 Attested Computation 字段。生产方可以
增加自定义字段，消费方应保留无法识别的字段。

### 文档索引

| 文档 | 用途 |
| --- | --- |
| [`SKILL.md`](./SKILL.md) | 完整的 Agent 工作流与约束规则 |
| [`references/spec-v02.md`](./references/spec-v02.md) | 固定版本的 OKF v0.2 实施参考 |
| [`references/examples.md`](./references/examples.md) | 来源、生命周期和 Attestation 示例 |
| [`references/conversion.md`](./references/conversion.md) | v0.1 迁移和数据源转换指南 |
| [`scripts/validate.sh`](./scripts/validate.sh) | 轻量级 v0.2 命令行校验器 |

### 版本与来源

| 项目 | 内容 |
| --- | --- |
| 当前适配的 OKF 版本 | `v0.2` |
| Skill 元数据版本 | `2.0` |
| 官方规范 | [`ad30107`](https://github.com/GoogleCloudPlatform/open-knowledge-format/blob/ad30107c31c06aec8a7d5636e0d1058118604e6f/SPEC.md) |
| 最初上游来源 | [`fabricioctelles/skills`](https://github.com/fabricioctelles/skills/tree/main/skills/okf-open-knowledge-format) |
| 未改动的 v0.1 基线 | [`8d4f71a`](https://github.com/fabricioctelles/skills/commit/8d4f71a188a81855ad96b11254b4d777462baca9) |

### 许可证

上游项目及 Skill 元数据声明该作品采用
[Apache License 2.0](https://github.com/fabricioctelles/skills/blob/main/LICENSE)。
重新分发时，请保留原始署名及适用的许可证声明。
