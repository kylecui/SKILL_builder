#!/usr/bin/env python3
# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///
"""Heuristic style checker for Petfish-style technical writing.

Usage:
  uv run scripts/style_check.py input.md
  python scripts/style_check.py input.md

The checker is intentionally conservative. It flags likely issues but does not replace human judgment.
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path

BUZZWORDS = [
    "赋能", "普惠", "拔高", "民主化", "银弹", "立体认知", "能力放大器", "蜂群式",
    "语不惊人死不休", "打造", "抓手", "质的飞跃", "全面升级", "颠覆式",
]

AI_OPENINGS = [
    "在当今", "随着技术的不断发展", "高度复杂", "日益严峻", "不可忽视", "新时代背景下",
]

WEAK_CLAIMS = [
    "具有重要意义", "具有重大意义", "极大提升", "全面提升", "完整闭环", "全链路闭环",
]

CONNECTORS = [
    "因此", "另一方面", "具体来说", "综上", "从这个角度", "这意味着", "在这种情况下",
    "However", "Therefore", "More specifically", "From this perspective",
]


def split_sentences(text: str) -> list[str]:
    parts = re.split(r"(?<=[。！？；.!?;])\s*", text)
    return [p.strip() for p in parts if p.strip()]


def count_chinese_chars(s: str) -> int:
    return len(re.findall(r"[\u4e00-\u9fff]", s))


def main() -> int:
    parser = argparse.ArgumentParser(description="Heuristic style checker for Petfish-style writing")
    parser.add_argument("file", help="Input text/markdown file")
    parser.add_argument("--long-cn", type=int, default=80, help="Chinese sentence length threshold")
    parser.add_argument("--long-en", type=int, default=35, help="English sentence word threshold")
    args = parser.parse_args()

    path = Path(args.file)
    if not path.exists():
        print(f"ERROR: file not found: {path}")
        return 2

    text = path.read_text(encoding="utf-8", errors="ignore")
    findings: list[str] = []

    for word in BUZZWORDS:
        if word in text:
            findings.append(f"BUZZWORD: found '{word}'")

    for phrase in AI_OPENINGS:
        if phrase in text:
            findings.append(f"AI_OPENING: found '{phrase}'")

    for phrase in WEAK_CLAIMS:
        if phrase in text:
            findings.append(f"WEAK_CLAIM: found '{phrase}', check whether it is supported by evidence")

    quote_count = text.count("“") + text.count("”") + text.count('"')
    if quote_count > 12:
        findings.append(f"QUOTES: many quotation marks detected ({quote_count}); check for rhetorical emphasis")

    sentences = split_sentences(text)
    for idx, sent in enumerate(sentences, 1):
        cn_len = count_chinese_chars(sent)
        en_words = len(re.findall(r"[A-Za-z]+", sent))
        if cn_len >= args.long_cn:
            findings.append(f"LONG_CN_SENTENCE #{idx}: {cn_len} Chinese chars: {sent[:80]}...")
        if en_words >= args.long_en:
            findings.append(f"LONG_EN_SENTENCE #{idx}: {en_words} English words: {sent[:100]}...")

    connector_hits = sum(text.count(c) for c in CONNECTORS)
    para_count = len([p for p in re.split(r"\n\s*\n", text) if p.strip()])
    if para_count >= 4 and connector_hits < 2:
        findings.append("STRUCTURE: few logical connectors found; check whether reasoning is explicit")

    if not findings:
        print("PASS: no obvious Petfish-style issues found.")
        return 0

    print("Style check findings:")
    for item in findings:
        print(f"- {item}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
