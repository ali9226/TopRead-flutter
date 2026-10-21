#!/usr/bin/env python3
"""Repeatable Tile Quest checks for development rules 8, 10 and 11.

Usage: python3 tool/tile_quest/audit_development_rules.py [dart-directory ...]
Bare weights and explicit red/green UI colors fail the check. Decorative palette
literals outside style files are reported for human review, not rewritten.
"""

from __future__ import annotations

import json
import argparse
from pathlib import Path
import re


project_root = Path(__file__).resolve().parents[2]
default_scopes = (
    "lib/pages/tile_quest",
    "lib/pages/user_info/widgets/tile_quest_entry",
)
token_pattern = re.compile(
    r"/\*.*?\*/|//[^\n]*|r?'''[\s\S]*?'''|r?\"\"\"[\s\S]*?\"\"\""
    r"|r?'(?:\\.|[^'\\])*'|r?\"(?:\\.|[^\"\\])*\""
    r"|[A-Za-z_]\w*|[^\s]",
    re.DOTALL,
)
weight_pattern = re.compile(r"\bFontWeight\s*\.\s*(?:w[1-9]00|bold|normal)\b")
semantic_color_pattern = re.compile(r"\bColors\.(?:red|green)(?:Accent)?\b")
literal_color_pattern = re.compile(r"\bColor\s*\(\s*0x[0-9a-fA-F]{8}\s*\)")
cjk_list_pattern = re.compile(r"\[(?:\s*['\"](?:zh|ja|ko)['\"]\s*,?){2,}\s*\]")


def mask_noncode(source: str) -> str:
    """Keep source offsets while ignoring comments and string literal contents."""
    characters = list(source)
    for match in token_pattern.finditer(source):
        token = match.group()
        if token.startswith(("//", "/*", "'", '"', "r'", 'r"')):
            for offset in range(match.start(), match.end()):
                if characters[offset] != "\n":
                    characters[offset] = " "
    return "".join(characters)


def bare_weights(code: str) -> list[int]:
    """Find weights outside an enclosing FontConfig.adjustedWeight call.

    Tracking the call stack supports multiline ternaries as well as the common
    one-line call, so compliant multiline TextStyle declarations remain valid.
    """
    tokens = list(token_pattern.finditer(code))
    calls: list[str] = []
    violations: list[int] = []
    for index, token in enumerate(tokens):
        text = token.group()
        if text == "(":
            previous = tokens[max(0, index - 3) : index]
            calls.append("".join(part.group() for part in previous))
        elif text == ")" and calls:
            calls.pop()
        elif text == "FontWeight" and index + 2 < len(tokens):
            weight = "".join(part.group() for part in tokens[index : index + 3])
            is_literal = bool(weight_pattern.fullmatch(weight))
            is_constructor = tokens[index + 1].group() == "("
            if (is_literal or is_constructor) and "FontConfig.adjustedWeight" not in calls:
                violations.append(token.start())
    return violations


def inspect(scopes: tuple[str, ...]) -> dict:
    files = sorted(
        {
            path
            for scope in scopes
            for path in (project_root / scope).rglob("*.dart")
        }
    )
    violations: list[dict] = []
    palette_review: list[dict] = []
    total_lines = 0
    weight_count = 0
    for path in files:
        source = path.read_text()
        code = mask_noncode(source)
        relative = str(path.relative_to(project_root))
        total_lines += len(source.splitlines())
        weight_count += len(weight_pattern.findall(code))

        def record(rule: str, offset: int, destination: list[dict]) -> None:
            destination.append(
                {"file": relative, "line": source.count("\n", 0, offset) + 1, "rule": rule}
            )

        for offset in bare_weights(code):
            record("unadjusted_font_weight", offset, violations)
        for match in semantic_color_pattern.finditer(code):
            record("use_color_constants_for_red_or_green", match.start(), violations)
        for match in cjk_list_pattern.finditer(source):
            if code[match.start()] == "[":
                record("use_language_util_for_cjk", match.start(), violations)
        # Literal art colors need contextual review: a ceramic tile or sky is a
        # deliberate visual asset, whereas danger/theme UI should share config.
        if not path.name.endswith("style.dart"):
            for match in literal_color_pattern.finditer(code):
                record("palette_literal_outside_style", match.start(), palette_review)
    return {
        "scopes": scopes,
        "dart_files": len(files),
        "source_lines": total_lines,
        "font_weight_references": weight_count,
        "violations": violations,
        "palette_review": palette_review,
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("scopes", nargs="*", help="Project-relative Dart directories")
    arguments = parser.parse_args()
    for scope in arguments.scopes:
        if not (project_root / scope).is_dir():
            parser.error(f"Dart directory does not exist: {scope}")
    report = inspect(tuple(arguments.scopes) or default_scopes)
    print(json.dumps(report, ensure_ascii=False, indent=2))
    raise SystemExit(bool(report["violations"]))
