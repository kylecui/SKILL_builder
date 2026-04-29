#!/usr/bin/env python3
# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///
"""Check text against Petfish-style writing rules.

Usage:
  uv run scripts/style_check.py --text "..."
  uv run scripts/style_check.py --file draft.md
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

CJK = r"\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff"
EN_TOKEN = r"[A-Za-z][A-Za-z0-9_.*+-]*"

AI_FLAVOR_PATTERNS = [
    # From V3
    "在当今",
    "高度复杂",
    "全面赋能",
    "能力闭环",
    "普惠",
    "拔高",
    "民主化",
    "极限",
    "银弹式",
    "立体认知",
    "多维协同",
    "重塑",
    "塑造",
    "从看得懂到管得住",
    # From petfish BUZZWORDS (deduplicated)
    "赋能",
    "银弹",
    "能力放大器",
    "蜂群式",
    "语不惊人死不休",
    "打造",
    "抓手",
    "质的飞跃",
    "全面升级",
    "颠覆式",
    # From petfish AI_OPENINGS (deduplicated)
    "随着技术的不断发展",
    "日益严峻",
    "不可忽视",
    "新时代背景下",
    # From petfish WEAK_CLAIMS
    "具有重要意义",
    "具有重大意义",
    "极大提升",
    "全面提升",
    "完整闭环",
    "全链路闭环",
]

LOGICAL_CONNECTORS = [
    # V3 connectors
    "因此",
    "另一方面",
    "具体来说",
    "综上所述",
    "从这个角度看",
    "这意味着",
    "有必要",
    # petfish English connectors
    "However",
    "Therefore",
    "More specifically",
    "From this perspective",
]


def split_sentences(text: str) -> list[str]:
    parts = re.split(r"(?<=[。！？.!?])\s*", text)
    return [p.strip() for p in parts if p.strip()]


def _is_code_or_heading(line: str) -> bool:
    """Return True for lines that should be skipped in spacing checks."""
    stripped = line.strip()
    return stripped.startswith("```") or stripped.startswith("    ")


def find_zh_en_spacing_issues(text: str) -> list[str]:
    """Find Chinese-English spacing violations including slash-separated terms."""
    issues: list[str] = []

    for line in text.split("\n"):
        if _is_code_or_heading(line):
            continue

        # Pattern 1: CJK + space(s) + English token
        issues.extend(re.findall(rf"[{CJK}]\s+{EN_TOKEN}", line))
        # Pattern 2: English token + space(s) + CJK
        issues.extend(re.findall(rf"{EN_TOKEN}\s+[{CJK}]", line))

    return sorted(set(issues))[:30]


def find_slash_spacing_issues(text: str) -> list[str]:
    """Find slash-separated term spacing violations.

    Detects patterns like:
      "API / CLI / SDK" (spaces around slashes between English tokens)
      "根据 API / CLI" (CJK space before slash group)
      "SDK / 配置文件" (slash group space before CJK)
    """
    issues: list[str] = []

    for line in text.split("\n"):
        if _is_code_or_heading(line):
            continue

        # Detect "EN space / space EN" patterns (spaced slashes between English tokens)
        matches = re.findall(
            rf"({EN_TOKEN}\s+/\s+{EN_TOKEN}(?:\s*/\s*{EN_TOKEN})*)",
            line,
        )
        issues.extend(matches)

        # Detect "/ space CJK" or "CJK space /" adjacent patterns
        issues.extend(re.findall(rf"/\s+[{CJK}]", line))
        issues.extend(re.findall(rf"[{CJK}]\s+/", line))

    return sorted(set(issues))[:20]


def check(text: str) -> dict:
    sentences = split_sentences(text)
    long_sentences = [s for s in sentences if len(s) > 80]
    ai_terms = [p for p in AI_FLAVOR_PATTERNS if p in text]
    spacing_issues = find_zh_en_spacing_issues(text)
    slash_issues = find_slash_spacing_issues(text)

    paragraphs = [p.strip() for p in re.split(r"\n\s*\n", text) if p.strip()]
    has_closure = False
    if paragraphs:
        last = paragraphs[-1]
        has_closure = any(
            k in last
            for k in [
                "因此",
                "综上所述",
                "有必要",
                "下一步",
                "建议",
                "可以",
                "应当",
                "需要",
            ]
        )

    connector_count = sum(text.count(c) for c in LOGICAL_CONNECTORS)

    score = 100
    score -= min(len(ai_terms) * 8, 32)
    score -= min(len(long_sentences) * 5, 25)
    score -= min(len(spacing_issues) * 4, 24)
    score -= min(len(slash_issues) * 4, 16)
    if connector_count == 0 and len(sentences) >= 3:
        score -= 10
    if not has_closure and len(paragraphs) >= 2:
        score -= 10
    score = max(score, 0)

    return {
        "score": score,
        "summary": {
            "sentence_count": len(sentences),
            "paragraph_count": len(paragraphs),
            "logical_connector_count": connector_count,
            "has_useful_closure": has_closure,
        },
        "issues": {
            "ai_flavor_terms": ai_terms,
            "long_sentences": long_sentences[:10],
            "zh_en_spacing_issues": spacing_issues,
            "slash_spacing_issues": slash_issues,
        },
        "recommendations": build_recommendations(
            ai_terms,
            long_sentences,
            spacing_issues,
            slash_issues,
            connector_count,
            has_closure,
        ),
    }


def build_recommendations(
    ai_terms, long_sentences, spacing_issues, slash_issues, connector_count, has_closure
):
    recs = []
    if ai_terms:
        recs.append(
            "Remove rhetorical or slogan-like expressions and replace them with concrete technical claims."
        )
    if long_sentences:
        recs.append(
            "Split long sentences so that each sentence carries one logical point."
        )
    if spacing_issues:
        recs.append(
            "Remove unnecessary spaces between Chinese text and English technical terms, for example Git提交 instead of Git 提交."
        )
    if slash_issues:
        recs.append(
            "Remove spaces around slashes in slash-separated English terms adjacent to Chinese, for example API/CLI/SDK instead of API / CLI / SDK."
        )
    if connector_count == 0:
        recs.append(
            "Add explicit logical connectors when the text contains multiple reasoning steps."
        )
    if not has_closure:
        recs.append(
            "Add a restrained closure that converges to necessity, next step, or bounded conclusion."
        )
    if not recs:
        recs.append("No major Petfish-style issues detected.")
    return recs


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Check text against Petfish-style writing rules."
    )
    src = parser.add_mutually_exclusive_group(required=True)
    src.add_argument("--text", help="Input text to check")
    src.add_argument("--file", help="Input file path")
    parser.add_argument("--json", action="store_true", help="Print JSON only")
    args = parser.parse_args()

    if args.file:
        text = Path(args.file).read_text(encoding="utf-8")
    else:
        text = args.text

    result = check(text)
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(f"Score: {result['score']}/100")
        print("\nSummary:")
        for k, v in result["summary"].items():
            print(f"  {k}: {v}")
        print("\nIssues:")
        for k, vals in result["issues"].items():
            print(f"  {k}:")
            if vals:
                for item in vals:
                    print(f"    - {item}")
            else:
                print("    (none)")
        print("\nRecommendations:")
        for r in result["recommendations"]:
            print(f"  - {r}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
