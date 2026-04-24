#!/usr/bin/env python3
# /// script
# requires-python = ">=3.9"
# ///
"""Simple style checker for Kyle-style writing.

Usage:
  uv run scripts/check_style.py <file>
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path

BAD_PHRASES = [
    "在当今高度复杂",
    "随着时代的发展",
    "赋能",
    "普惠",
    "拔高",
    "民主化",
    "银弹式",
    "重塑格局",
    "颠覆式",
    "完整能力闭环",
    "体系化对抗",
    "语不惊人死不休",
]

CONNECTORS = [
    "因此",
    "另一方面",
    "具体来说",
    "综上所述",
    "However",
    "Therefore",
    "Specifically",
    "In practice",
]


def split_sentences(text: str) -> list[str]:
    parts = re.split(r"(?<=[。！？.!?])\s*", text)
    return [p.strip() for p in parts if p.strip()]


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Check text for Kyle-style writing issues."
    )
    parser.add_argument("file", help="Text or markdown file to check")
    args = parser.parse_args()

    path = Path(args.file)
    if not path.exists():
        print(f"ERROR: file not found: {path}")
        return 2

    text = path.read_text(encoding="utf-8", errors="ignore")
    sentences = split_sentences(text)

    issues: list[str] = []

    for phrase in BAD_PHRASES:
        if phrase in text:
            issues.append(f"Avoid phrase: {phrase}")

    long_sentences = [s for s in sentences if len(s) > 120]
    if long_sentences:
        issues.append(
            f"Long sentences found: {len(long_sentences)} sentence(s) over 120 chars"
        )
        for s in long_sentences[:3]:
            issues.append(f"  - {s[:120]}...")

    connector_count = sum(text.count(c) for c in CONNECTORS)
    if len(text) > 600 and connector_count == 0:
        issues.append("No explicit logical connector found in a long text")

    quote_count = text.count("“") + text.count("”") + text.count('"')
    if quote_count > 12:
        issues.append(f"Too many quotation marks: {quote_count}")

    if issues:
        print("STYLE CHECK: NEEDS REVIEW")
        for issue in issues:
            print(f"- {issue}")
        return 1

    print("STYLE CHECK: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
