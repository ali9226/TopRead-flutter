#!/usr/bin/env python3
"""Scan handwritten Dart filenames, adjusted weights and CJK language lists.

Only three deterministic rules are enforced. Tile Quest artwork/color checks
are deliberately excluded. FontConfig and LanguageUtil are canonical sources;
generated Dart files are excluded. Exit 1 means a rule violation, 2 invalid input.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re

from tile_quest.audit_development_rules import (
    bare_weights,
    cjk_list_pattern,
    mask_noncode,
    weight_pattern,
)


project_root = Path(__file__).resolve().parents[1]
file_name_pattern = re.compile(r"[a-z][a-z0-9]*(?:_[a-z0-9]+)*\.dart")
canonical_sources = {
    "lib/config/font_config.dart",
    "lib/util/language_util/index.dart",
}
generated_suffixes = (".g.dart", ".freezed.dart", ".gen.dart", ".gr.dart")


def is_generated(path: Path, source: str) -> bool:
    """Recognize generated suffixes and standard generator source headers."""
    return (
        path.name.endswith(generated_suffixes)
        or path.name == "generated_plugin_registrant.dart"
        or "GENERATED CODE - DO NOT MODIFY BY HAND" in source[:1024]
        or "GENERATED CODE - DO NOT EDIT" in source[:1024]
    )


def inspect_sources(paths: list[Path]) -> dict:
    files = sorted(
        {
            file
            for path in paths
            for file in ([path] if path.is_file() else path.rglob("*.dart"))
            if file.suffix == ".dart"
        }
    )
    violations: list[dict] = []
    excluded_sources: list[str] = []
    generated_files: list[str] = []
    checked_files = 0
    references = 0
    for path in files:
        relative = str(path.relative_to(project_root))
        source = path.read_text()
        if is_generated(path, source):
            generated_files.append(relative)
            continue
        if not file_name_pattern.fullmatch(path.name):
            violations.append({"file": relative, "line": 1, "rule": "snake_case_file_name"})
        if relative in canonical_sources:
            excluded_sources.append(relative)
            continue
        checked_files += 1
        code = mask_noncode(source)
        references += len(weight_pattern.findall(code))

        def record(rule: str, offset: int) -> None:
            line = source.count("\n", 0, offset) + 1
            violations.append(
                {
                    "file": relative,
                    "line": line,
                    "rule": rule,
                    "source": source.splitlines()[line - 1].strip(),
                }
            )

        for offset in bare_weights(code):
            record("unadjusted_font_weight", offset)
        for match in cjk_list_pattern.finditer(source):
            # Masked strings/comments cannot begin a real Dart list expression.
            if code[match.start()] == "[":
                record("use_language_util_for_cjk", match.start())
    return {
        "dart_files": len(files),
        "checked_sources": checked_files,
        "font_weight_references": references,
        "canonical_sources": excluded_sources,
        "generated_files": generated_files,
        "violations": violations,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", help="Project-relative Dart files or directories; default lib")
    arguments = parser.parse_args()
    paths = [project_root / value for value in arguments.paths or ["lib"]]
    for path in paths:
        if not path.exists() or not path.is_relative_to(project_root):
            parser.error(f"Project source does not exist: {path}")
    report = inspect_sources(paths)
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return int(bool(report["violations"]))


if __name__ == "__main__":
    raise SystemExit(main())
