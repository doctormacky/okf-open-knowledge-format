#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["PyYAML>=6.0,<7"]
# ///

from __future__ import annotations

import argparse
import datetime as dt
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import yaml
from yaml.constructor import ConstructorError
from yaml.nodes import MappingNode
from yaml.resolver import BaseResolver


class OKFLoader(yaml.SafeLoader):
    pass


# OKF treats timestamp text as YAML 1.2 strings and accepts only true/false as
# booleans. PyYAML otherwise applies YAML 1.1 coercions.
OKFLoader.yaml_implicit_resolvers = {
    key: [
        resolver
        for resolver in resolvers
        if resolver[0]
        not in {
            "tag:yaml.org,2002:timestamp",
            "tag:yaml.org,2002:bool",
        }
    ]
    for key, resolvers in yaml.SafeLoader.yaml_implicit_resolvers.items()
}
OKFLoader.add_implicit_resolver(
    "tag:yaml.org,2002:bool",
    re.compile(r"^(?:true|false)$", re.IGNORECASE),
    list("tTfF"),
)


def construct_unique_mapping(
    loader: OKFLoader, node: MappingNode, deep: bool = False
) -> dict[Any, Any]:
    mapping: dict[Any, Any] = {}
    for key_node, value_node in node.value:
        key = loader.construct_object(key_node, deep=deep)
        try:
            duplicate = key in mapping
        except TypeError as exc:
            raise ConstructorError(
                "while constructing a mapping",
                node.start_mark,
                "found an unhashable mapping key",
                key_node.start_mark,
            ) from exc
        if duplicate:
            raise ConstructorError(
                "while constructing a mapping",
                node.start_mark,
                f"found duplicate key {key!r}",
                key_node.start_mark,
            )
        mapping[key] = loader.construct_object(value_node, deep=deep)
    return mapping


OKFLoader.add_constructor(BaseResolver.DEFAULT_MAPPING_TAG, construct_unique_mapping)

TIMESTAMP_RE = re.compile(
    r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}"
    r"(?::\d{2}(?:\.\d+)?)?(?:Z|[+-]\d{2}:\d{2})$"
)


@dataclass(frozen=True)
class Diagnostic:
    severity: str
    code: str
    path: str
    message: str


class Validator:
    def __init__(self, root: Path) -> None:
        self.root = root.resolve()
        self.diagnostics: list[Diagnostic] = []
        self.concepts = 0
        self.reserved = 0

    def error(self, code: str, path: str, message: str) -> None:
        self.diagnostics.append(Diagnostic("error", code, path, message))

    def warning(self, code: str, path: str, message: str) -> None:
        self.diagnostics.append(Diagnostic("warning", code, path, message))

    @property
    def error_count(self) -> int:
        return sum(item.severity == "error" for item in self.diagnostics)

    @property
    def warning_count(self) -> int:
        return sum(item.severity == "warning" for item in self.diagnostics)

    def run(self) -> None:
        for path in sorted(self.root.rglob("*.md")):
            if not path.is_file():
                continue
            relative = path.relative_to(self.root).as_posix()
            reserved = path.name in {"index.md", "log.md"}
            if reserved:
                self.reserved += 1
            else:
                self.concepts += 1

            try:
                text = path.read_text(encoding="utf-8")
            except (UnicodeDecodeError, OSError) as exc:
                code = "E3" if reserved else "E1"
                self.error(code, relative, f"file must be readable UTF-8: {exc}")
                continue

            if path.name == "index.md":
                self.validate_index(path, relative, text)
            elif path.name == "log.md":
                self.validate_log(relative, text)
            else:
                self.validate_concept(relative, text)

    def parse_frontmatter(
        self, text: str
    ) -> tuple[dict[str, Any] | None, str, str | None]:
        lines = text.splitlines()
        if not lines or lines[0] != "---":
            return None, text, "no YAML frontmatter"
        try:
            closing = lines.index("---", 1)
        except ValueError:
            return None, "", "frontmatter has no closing delimiter"

        raw = "\n".join(lines[1:closing])
        try:
            data = yaml.load(raw, Loader=OKFLoader)
        except yaml.YAMLError as exc:
            problem = getattr(exc, "problem", None) or "invalid YAML"
            return None, "", f"frontmatter is not parseable YAML: {problem}"
        if not isinstance(data, dict):
            return None, "", "frontmatter must be a YAML mapping"
        return data, "\n".join(lines[closing + 1 :]), None

    def validate_index(self, path: Path, relative: str, text: str) -> None:
        is_root = path.parent.resolve() == self.root
        body = text
        if text.startswith("---\n") or text == "---":
            data, body, problem = self.parse_frontmatter(text)
            if not is_root:
                self.error(
                    "E3",
                    relative,
                    "only the bundle-root index.md may have frontmatter",
                )
            elif problem:
                self.error("E3", relative, problem)
                return
            elif data is not None and data.get("okf_version") != "0.2":
                self.error(
                    "E3",
                    relative,
                    'root index must declare okf_version: "0.2"',
                )

        if not re.search(r"^#\s+\S", body, re.MULTILINE):
            self.error("E3", relative, "index.md requires a heading")
        if not re.search(r"^[*+-]\s+\[[^\]]+]\([^)]+\)", body, re.MULTILINE):
            self.error("E3", relative, "index.md requires a linked entry")

    def validate_log(self, relative: str, text: str) -> None:
        if text.startswith("---\n") or text == "---":
            self.error("E3", relative, "log.md must not have frontmatter")
        headings = re.findall(r"^##\s+(.+?)\s*$", text, re.MULTILINE)
        if not headings:
            self.error("E3", relative, "log.md requires ## YYYY-MM-DD groups")
            return
        dates: list[dt.date] = []
        for heading in headings:
            try:
                dates.append(dt.date.fromisoformat(heading))
            except ValueError:
                self.error("E3", relative, f"invalid log date heading: {heading}")
        if len(dates) == len(headings) and dates != sorted(dates, reverse=True):
            self.error("E3", relative, "log dates must be newest first")

    def validate_concept(self, relative: str, text: str) -> None:
        data, body, problem = self.parse_frontmatter(text)
        if problem:
            self.error("E1", relative, problem)
            return
        assert data is not None

        if not self.nonempty_string(data.get("type")):
            self.error("E2", relative, "concept requires non-empty string type")
            return

        for field in ("title", "description"):
            if field not in data:
                self.warning("W1", relative, f"missing recommended {field}")
            elif not self.nonempty_string(data[field]):
                self.error("E4", relative, f"{field} must be a non-empty string")

        if "resource" in data and not self.nonempty_string(data["resource"]):
            self.error("E4", relative, "resource must be a non-empty string")
        if "tags" in data and (
            not isinstance(data["tags"], list)
            or not all(self.nonempty_string(tag) for tag in data["tags"])
        ):
            self.error("E4", relative, "tags must be a list of strings")

        self.validate_sources(data, relative)
        self.validate_generated(data, relative)
        self.validate_verified(data, relative)

        if "status" in data and data["status"] not in {
            "draft",
            "stable",
            "deprecated",
        }:
            self.error("E4", relative, "status must be draft, stable, or deprecated")
        if "stale_after" in data:
            self.validate_timestamp(data["stale_after"], relative, "stale_after")
        if "usage_window" in data:
            self.validate_usage_window(data["usage_window"], relative, "usage_window")

        if data["type"] == "Attested Computation":
            self.validate_attested(data, body, relative)

        if "timestamp" in data:
            self.warning(
                "W6",
                relative,
                "legacy timestamp is superseded by generated.at",
            )
        if re.search(r"^# Citations\s*$", body, re.MULTILINE):
            self.warning(
                "W6",
                relative,
                "legacy # Citations is superseded by sources",
            )

    def validate_sources(self, data: dict[str, Any], relative: str) -> None:
        if "sources" not in data:
            return
        sources = data["sources"]
        if not isinstance(sources, list):
            self.error("E4", relative, "sources must be a list")
            return
        for index, source in enumerate(sources):
            if not isinstance(source, dict):
                self.error("E4", relative, f"sources[{index}] must be a mapping")
                continue
            if not self.nonempty_string(source.get("resource")):
                self.error("E4", relative, f"sources[{index}].resource is required")
            for field in ("id", "title", "author"):
                if field in source and not self.nonempty_string(source[field]):
                    self.error(
                        "E4",
                        relative,
                        f"sources[{index}].{field} must be a string",
                    )
            if "last_modified" in source:
                self.validate_timestamp(
                    source["last_modified"],
                    relative,
                    f"sources[{index}].last_modified",
                )
            if "usage_count" in source and (
                isinstance(source["usage_count"], bool)
                or not isinstance(source["usage_count"], (int, float))
            ):
                self.error(
                    "E4",
                    relative,
                    f"sources[{index}].usage_count must be numeric",
                )
            if "usage_window" in source:
                self.validate_usage_window(
                    source["usage_window"],
                    relative,
                    f"sources[{index}].usage_window",
                )

    def validate_generated(self, data: dict[str, Any], relative: str) -> None:
        if "generated" not in data:
            return
        generated = data["generated"]
        if not isinstance(generated, dict):
            self.error("E4", relative, "generated must be a mapping")
            return
        if not self.nonempty_string(generated.get("by")):
            self.error("E4", relative, "generated.by is required")
        if "at" in generated:
            self.validate_timestamp(generated["at"], relative, "generated.at")

    def validate_verified(self, data: dict[str, Any], relative: str) -> None:
        if "verified" not in data:
            return
        raw = data["verified"]
        events = [raw] if isinstance(raw, dict) else raw
        if not isinstance(events, list):
            self.error("E4", relative, "verified must be a mapping or list")
            return
        for index, event in enumerate(events):
            if not isinstance(event, dict):
                self.error("E4", relative, f"verified[{index}] must be a mapping")
                continue
            if not self.nonempty_string(event.get("by")):
                self.error("E4", relative, f"verified[{index}].by is required")
            if "at" not in event:
                self.error("E4", relative, f"verified[{index}].at is required")
            else:
                self.validate_timestamp(event["at"], relative, f"verified[{index}].at")

    def validate_usage_window(self, value: Any, relative: str, field: str) -> None:
        if not isinstance(value, dict):
            self.error("E4", relative, f"{field} must be a mapping")
            return
        for endpoint in ("from", "to"):
            if endpoint not in value:
                self.error("E4", relative, f"{field}.{endpoint} is required")
            else:
                self.validate_timestamp(
                    value[endpoint], relative, f"{field}.{endpoint}"
                )

    def validate_attested(self, data: dict[str, Any], body: str, relative: str) -> None:
        if not self.nonempty_string(data.get("runtime")):
            self.error("E4", relative, "Attested Computation requires runtime")

        computation = data.get("computation")
        if computation is not None and not self.nonempty_string(computation):
            self.error("E4", relative, "computation must be a path string")
        inline = self.has_inline_computation(body)
        if computation is None and not inline:
            self.error(
                "E4",
                relative,
                "Attested Computation requires inline code or computation path",
            )
        if computation is not None and inline:
            self.error(
                "E4",
                relative,
                "inline code and computation path are mutually exclusive",
            )

        if "parameters" in data:
            parameters = data["parameters"]
            if not isinstance(parameters, list):
                self.error("E4", relative, "parameters must be a list")
            else:
                for index, parameter in enumerate(parameters):
                    if not isinstance(parameter, dict):
                        self.error(
                            "E4", relative, f"parameters[{index}] must be a mapping"
                        )
                        continue
                    if not self.nonempty_string(parameter.get("name")):
                        self.error(
                            "E4", relative, f"parameters[{index}].name is required"
                        )
                    if not self.nonempty_string(parameter.get("type")):
                        self.error(
                            "E4", relative, f"parameters[{index}].type is required"
                        )
                    if not isinstance(parameter.get("required"), bool):
                        self.error(
                            "E4",
                            relative,
                            f"parameters[{index}].required must be boolean",
                        )

        for field in ("executor", "attester"):
            if field not in data:
                continue
            value = data[field]
            if not isinstance(value, dict):
                self.error("E4", relative, f"{field} must be a mapping")
            elif not self.nonempty_string(value.get("resource")):
                self.error("E4", relative, f"{field}.resource is required")
            elif (
                field == "executor"
                and "receipt" in value
                and (
                    not isinstance(value["receipt"], list)
                    or not all(self.nonempty_string(item) for item in value["receipt"])
                )
            ):
                self.error(
                    "E4",
                    relative,
                    "executor.receipt must be a list of field names",
                )

    def validate_timestamp(self, value: Any, relative: str, field: str) -> None:
        if not isinstance(value, str) or not TIMESTAMP_RE.fullmatch(value):
            self.error(
                "E4",
                relative,
                f"{field} must be an ISO 8601 datetime with explicit offset",
            )
            return
        try:
            dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
        except ValueError:
            self.error("E4", relative, f"{field} is not a valid datetime")

    @staticmethod
    def has_inline_computation(body: str) -> bool:
        match = re.search(r"^# Computation\s*$", body, re.MULTILINE)
        if not match:
            return False
        section = body[match.end() :]
        next_heading = re.search(r"^#\s+", section, re.MULTILINE)
        if next_heading:
            section = section[: next_heading.start()]
        return bool(re.search(r"^(?:```|~~~|    \S)", section, re.MULTILINE))

    @staticmethod
    def nonempty_string(value: Any) -> bool:
        return isinstance(value, str) and bool(value.strip())


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate an OKF v0.2 bundle")
    parser.add_argument("bundle", nargs="?", default=".", type=Path)
    args = parser.parse_args()
    if not args.bundle.is_dir():
        print(f"ERROR: '{args.bundle}' is not a directory", file=sys.stderr)
        return 2

    validator = Validator(args.bundle)
    validator.run()
    print(f"Validating OKF v0.2 bundle: {args.bundle}")
    print("---")
    for item in validator.diagnostics:
        label = "ERROR" if item.severity == "error" else "WARNING"
        print(f"{label} {item.code}: {item.path} - {item.message}")
    print("---")
    print(
        f"Concepts: {validator.concepts} | Reserved files: {validator.reserved} "
        f"| Errors: {validator.error_count} | Warnings: {validator.warning_count}"
    )
    if validator.error_count:
        print("FAIL: bundle is not valid OKF v0.2")
        return 1
    print("PASS: bundle is valid OKF v0.2")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
