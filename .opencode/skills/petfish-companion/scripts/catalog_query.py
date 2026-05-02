#!/usr/bin/env python3
"""
PEtFiSh Companion — Skill Catalog Query

Reads the skill-catalog.md reference file and supports:
  --list          List all packs with aliases and descriptions
  --search TERM   Search packs by keyword (matches name, triggers, capabilities)
  --profile NAME  Show packs auto-installed for a given profile
  --json          Output as JSON instead of plain text

Usage:
  uv run catalog_query.py --list
  uv run catalog_query.py --search 部署
  uv run catalog_query.py --profile code
  uv run catalog_query.py --search deploy --json
"""

import argparse
import json
import re
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Catalog data (embedded for zero-dependency operation)
# Keep in sync with references/skill-catalog.md
# ---------------------------------------------------------------------------

CATALOG = [
    {
        "alias": "init",
        "pack": "project-initializer-skill",
        "description": "项目初始化器 — 创建标准目录结构、自动安装推荐skill、运行post-init wizard",
        "install_scope": "global",
        "skill_count": 1,
        "triggers": ["初始化", "新项目", "project init", "scaffold", "创建项目"],
    },
    {
        "alias": "companion",
        "pack": "petfish-companion-skill",
        "description": "常驻伙伴 — 感知需求、推荐skill、管理已装状态、连接三方市场",
        "install_scope": "global",
        "skill_count": 1,
        "triggers": ["/petfish", "what skills", "what can you do", "help with"],
    },
    {
        "alias": "course",
        "pack": "opencode-course-skills-pack",
        "description": "课程开发全生命周期 — 规划、提纲、正文、实验、资料、QA/QC",
        "install_scope": "project",
        "skill_count": 15,
        "triggers": [
            "课程",
            "教学",
            "大纲",
            "课时",
            "模块",
            "学员",
            "教师",
            "实验",
            "QA",
            "QC",
            "发布",
            "讲义",
        ],
    },
    {
        "alias": "deploy",
        "pack": "repo-deploy-ops-skill-pack",
        "description": "部署与运维 — 运行时识别、主机检查、部署执行、验证、运维、回滚",
        "install_scope": "project",
        "skill_count": 7,
        "triggers": [
            "部署",
            "上线",
            "deploy",
            "Docker",
            "服务器",
            "运维",
            "回滚",
            "health check",
            "systemctl",
            "nginx",
        ],
    },
    {
        "alias": "petfish",
        "pack": "petfish-style-skill",
        "description": "工程写作风格改写 — 去AI味、说人话、中英文紧凑混排",
        "install_scope": "project",
        "skill_count": 1,
        "triggers": [
            "说人话",
            "润色",
            "去AI味",
            "风格",
            "改写",
            "rewrite",
            "polish",
            "humanize",
        ],
    },
    {
        "alias": "ppt",
        "pack": "opencode-ppt-skills",
        "description": "PPT设计与制作 — 读取/生成PPTX、Slide QA、视觉渲染",
        "install_scope": "project",
        "skill_count": 2,
        "triggers": ["PPT", "幻灯片", "演示", "slide", "deck", "presentation", "PPTX"],
    },
    {
        "alias": "testdocs",
        "pack": "opencode-skill-pack-testcases-usage-docs",
        "description": "测试用例与使用文档生成 — test case、覆盖率、README、API docs",
        "install_scope": "project",
        "skill_count": 2,
        "triggers": [
            "测试用例",
            "test case",
            "测试矩阵",
            "文档",
            "README",
            "usage docs",
            "API docs",
        ],
    },
]

PROFILES = {
    "minimal": ["petfish"],
    "course": ["course", "petfish"],
    "code": ["deploy", "petfish", "testdocs"],
    "ops": ["deploy", "petfish"],
    "security": ["deploy", "petfish", "testdocs"],
    "writing": ["petfish", "ppt"],
    "skills-package": ["petfish", "testdocs"],
    "comprehensive": ["course", "deploy", "petfish", "ppt", "testdocs"],
}


def list_packs(as_json: bool = False):
    """List all packs."""
    if as_json:
        print(json.dumps(CATALOG, ensure_ascii=False, indent=2))
        return

    print("┌─────────────────────────────────────────────────────────────┐")
    print("│  ><(((^>  PEtFiSh Skill Catalog                           │")
    print("├───────────┬─────────────────────────────────────────────────┤")
    for p in CATALOG:
        alias = p["alias"].ljust(10)
        desc = p["description"][:48]
        scope = "🌐" if p["install_scope"] == "global" else "📁"
        print(f"│ {scope} {alias}│ {desc.ljust(48)}│")
    print("└───────────┴─────────────────────────────────────────────────┘")
    print()
    print("🌐 = global install   📁 = project install")
    print("Use --search <keyword> to filter by capability.")


def search_packs(term: str, as_json: bool = False):
    """Search packs by keyword across name, description, and triggers."""
    term_lower = term.lower()
    results = []
    for p in CATALOG:
        searchable = " ".join(
            [
                p["alias"],
                p["pack"],
                p["description"],
                " ".join(p["triggers"]),
            ]
        ).lower()
        if term_lower in searchable:
            results.append(p)

    if as_json:
        print(json.dumps(results, ensure_ascii=False, indent=2))
        return

    if not results:
        print(f"No packs found matching '{term}'.")
        return

    print(f"Found {len(results)} pack(s) matching '{term}':\n")
    for p in results:
        matched = [t for t in p["triggers"] if term_lower in t.lower()]
        print(f"  {p['alias']} — {p['pack']}")
        print(f"    {p['description']}")
        if matched:
            print(f"    Matched triggers: {', '.join(matched)}")
        print()


def show_profile(name: str, as_json: bool = False):
    """Show packs for a given profile."""
    if name not in PROFILES:
        print(f"Unknown profile '{name}'. Available: {', '.join(PROFILES.keys())}")
        sys.exit(1)

    aliases = PROFILES[name]
    packs = [p for p in CATALOG if p["alias"] in aliases]

    if as_json:
        print(
            json.dumps({"profile": name, "packs": packs}, ensure_ascii=False, indent=2)
        )
        return

    print(f"Profile: {name}")
    print(f"Auto-installed packs ({len(aliases)}):\n")
    for p in packs:
        print(f"  {p['alias'].ljust(12)} {p['description']}")
    print()


def main():
    parser = argparse.ArgumentParser(description="PEtFiSh Skill Catalog Query")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--list", action="store_true", help="List all packs")
    group.add_argument("--search", type=str, help="Search by keyword")
    group.add_argument("--profile", type=str, help="Show packs for a profile")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    args = parser.parse_args()

    if args.list:
        list_packs(as_json=args.json)
    elif args.search:
        search_packs(args.search, as_json=args.json)
    elif args.profile:
        show_profile(args.profile, as_json=args.json)


if __name__ == "__main__":
    main()
