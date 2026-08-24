<div align="center">

# OKF Open Knowledge Format

**An AI-agent skill for creating, validating, enriching, and converting Open Knowledge Format bundles.**

**用于创建、校验、丰富和转换开放知识格式（OKF）知识包的 AI Agent Skill。**

[English](#english) | [简体中文](#简体中文)

![OKF Spec](https://img.shields.io/badge/OKF-v0.1%20Draft-2563eb)
![Skill Version](https://img.shields.io/badge/Skill-v1.1-0f766e)
[![License](https://img.shields.io/badge/License-Apache--2.0-d97706)](https://github.com/fabricioctelles/skills/blob/main/LICENSE)

</div>

> [!IMPORTANT]
> **Provenance / 来源说明**
>
> The `v0.1` baseline in this repository is reproduced without changes from
> [`fabricioctelles/skills/skills/okf-open-knowledge-format`](https://github.com/fabricioctelles/skills/tree/main/skills/okf-open-knowledge-format).
> The five upstream skill files are byte-for-byte identical to upstream commit
> [`8d4f71a`](https://github.com/fabricioctelles/skills/commit/8d4f71a188a81855ad96b11254b4d777462baca9).
>
> 本仓库的 `v0.1` 基线原样来自
> [`fabricioctelles/skills/skills/okf-open-knowledge-format`](https://github.com/fabricioctelles/skills/tree/main/skills/okf-open-knowledge-format)，
> 未对 5 个上游 Skill 文件做任何修改；其内容与上游提交
> [`8d4f71a`](https://github.com/fabricioctelles/skills/commit/8d4f71a188a81855ad96b11254b4d777462baca9)
> 逐字节一致。本 README 仅用于补充项目说明，不属于上游 Skill 内容。

---

## English

### Overview

Open Knowledge Format (OKF) is a vendor-neutral, human- and agent-readable
format for representing organizational knowledge as Markdown files with YAML
frontmatter. An OKF knowledge bundle is simply a directory tree: it requires no
SDK, central registry, or proprietary platform.

This repository packages an AI-agent skill that teaches compatible agents how
to create, validate, enrich, and convert OKF bundles while following the OKF
v0.1 draft specification.

### What This Skill Does

- Creates conformant OKF bundles and concept documents.
- Validates required frontmatter, reserved files, and recommended metadata.
- Enriches existing concepts with schemas, examples, citations, and links.
- Converts Notion exports, Obsidian vaults, CSV files, and spreadsheets to OKF.
- Preserves producer-defined metadata and tolerates unknown concept types.
- Provides guidance for Google Cloud Knowledge Catalog and `kcmd` workflows.

### Repository Structure

```text
.
├── SKILL.md                   # Agent instructions and operating rules
├── README.md                  # Bilingual project documentation
├── references/
│   ├── conversion.md         # Source-to-OKF conversion guides
│   ├── examples.md           # Complete example bundles
│   └── spec-v01.md           # OKF v0.1 draft specification
└── scripts/
    └── validate.sh           # Lightweight OKF conformance validator
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
Validate this directory against the OKF v0.1 specification.
Convert this Obsidian vault into an OKF knowledge bundle.
Enrich these OKF concepts with schemas, citations, and cross-links.
```

To run the bundled lightweight validator directly:

```bash
./scripts/validate.sh /path/to/your/bundle
```

The validator checks the three core conformance rules:

1. Every non-reserved Markdown file has YAML frontmatter.
2. Every concept has a non-empty `type` field.
3. Reserved `index.md` and `log.md` files follow their structural rules.

When available, [`okflint`](https://github.com/mattdav/okflint) is recommended
for deeper validation, including profiles, link resolution, and JSON output.

### OKF at a Glance

A minimal OKF concept looks like this:

```markdown
---
type: Metric
title: Monthly Recurring Revenue
description: Active subscription revenue normalized to a monthly amount.
tags: [revenue, saas]
---

# Monthly Recurring Revenue

The sum of all active subscriptions normalized to a monthly amount.
```

Only `type` is required. Fields such as `title`, `description`, `resource`,
`tags`, and `timestamp` are recommended or optional. Producers may add custom
fields, and consumers should preserve fields they do not recognize.

### Documentation

| Document | Purpose |
| --- | --- |
| [`SKILL.md`](./SKILL.md) | Complete agent workflow and guardrails |
| [`references/spec-v01.md`](./references/spec-v01.md) | OKF v0.1 draft specification |
| [`references/examples.md`](./references/examples.md) | Examples for analytics, incident response, and APIs |
| [`references/conversion.md`](./references/conversion.md) | Notion, Obsidian, CSV, and spreadsheet conversion guides |
| [`scripts/validate.sh`](./scripts/validate.sh) | Basic command-line conformance validator |

### Version and Provenance

| Item | Value |
| --- | --- |
| Repository baseline | `v0.1` |
| Changes to upstream skill files | None |
| Upstream source | [`fabricioctelles/skills`](https://github.com/fabricioctelles/skills/tree/main/skills/okf-open-knowledge-format) |
| Verified upstream commit | [`8d4f71a`](https://github.com/fabricioctelles/skills/commit/8d4f71a188a81855ad96b11254b4d777462baca9) |
| OKF specification | `v0.1 Draft` |
| Skill metadata version | `1.1` |

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

本仓库提供一个 AI Agent Skill，指导兼容的 Agent 按照 OKF v0.1 草案创建、校验、
丰富和转换 OKF 知识包。

### 主要能力

- 创建符合规范的 OKF 知识包和概念文档。
- 校验必填 Frontmatter、保留文件以及推荐元数据。
- 为现有概念补充 Schema、示例、引用和交叉链接。
- 将 Notion 导出、Obsidian Vault、CSV 和电子表格转换为 OKF。
- 保留生产方自定义元数据，并兼容未知的概念类型。
- 提供 Google Cloud Knowledge Catalog 和 `kcmd` 工作流指引。

### 仓库结构

```text
.
├── SKILL.md                   # Agent 指令与执行规则
├── README.md                  # 中英文项目说明
├── references/
│   ├── conversion.md         # 各类数据源到 OKF 的转换指南
│   ├── examples.md           # 完整知识包示例
│   └── spec-v01.md           # OKF v0.1 规范草案
└── scripts/
    └── validate.sh           # 轻量级 OKF 合规校验脚本
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
按照 OKF v0.1 规范校验这个目录。
将这个 Obsidian Vault 转换为 OKF 知识包。
使用 Schema、引用和交叉链接丰富这些 OKF 概念。
```

也可以直接运行仓库内置的轻量级校验器：

```bash
./scripts/validate.sh /path/to/your/bundle
```

该脚本检查 3 条核心合规规则：

1. 每个非保留 Markdown 文件都包含 YAML Frontmatter。
2. 每个概念都包含非空的 `type` 字段。
3. 保留文件 `index.md` 和 `log.md` 符合各自的结构规则。

如环境允许，建议优先使用 [`okflint`](https://github.com/mattdav/okflint)
进行更完整的校验，包括 Profile、链接解析和 JSON 输出。

### OKF 最小示例

```markdown
---
type: Metric
title: Monthly Recurring Revenue
description: Active subscription revenue normalized to a monthly amount.
tags: [revenue, saas]
---

# Monthly Recurring Revenue

The sum of all active subscriptions normalized to a monthly amount.
```

只有 `type` 是必填字段。`title`、`description`、`resource`、`tags` 和
`timestamp` 属于推荐或可选字段。生产方可以增加自定义字段，消费方应保留无法识别
的字段。

### 文档索引

| 文档 | 用途 |
| --- | --- |
| [`SKILL.md`](./SKILL.md) | 完整的 Agent 工作流与约束规则 |
| [`references/spec-v01.md`](./references/spec-v01.md) | OKF v0.1 规范草案 |
| [`references/examples.md`](./references/examples.md) | 分析、故障响应和 API 场景示例 |
| [`references/conversion.md`](./references/conversion.md) | Notion、Obsidian、CSV 和电子表格转换指南 |
| [`scripts/validate.sh`](./scripts/validate.sh) | 基础命令行合规校验器 |

### 版本与来源

| 项目 | 内容 |
| --- | --- |
| 仓库基线版本 | `v0.1` |
| 上游 Skill 文件改动 | 无 |
| 上游来源 | [`fabricioctelles/skills`](https://github.com/fabricioctelles/skills/tree/main/skills/okf-open-knowledge-format) |
| 已核对的上游提交 | [`8d4f71a`](https://github.com/fabricioctelles/skills/commit/8d4f71a188a81855ad96b11254b4d777462baca9) |
| OKF 规范版本 | `v0.1 Draft` |
| Skill 元数据版本 | `1.1` |

### 许可证

上游项目及 Skill 元数据声明该作品采用
[Apache License 2.0](https://github.com/fabricioctelles/skills/blob/main/LICENSE)。
重新分发时，请保留原始署名及适用的许可证声明。
