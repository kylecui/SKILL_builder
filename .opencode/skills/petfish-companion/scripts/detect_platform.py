#!/usr/bin/env python3
"""
PEtFiSh Companion — Platform Detection

Detects which AI coding platform(s) are active for a given project
by checking for platform-specific marker files/directories.

Uses platforms.json as the source of truth for detect_markers.

Usage:
  uv run detect_platform.py --target /path/to/project
  uv run detect_platform.py --target . --json
  uv run detect_platform.py --target . --first
"""

import argparse
import json
import sys
from pathlib import Path

# Fallback markers if platforms.json is not available
FALLBACK_MARKERS = {
    "opencode": [".opencode", "opencode.json"],
    "claude": [".claude", "CLAUDE.md"],
    "codex": [".codex"],
    "cursor": [".cursor", ".cursorrules"],
    "copilot": [".github/copilot-instructions.md", ".github/skills"],
    "windsurf": [".windsurf", ".windsurfrules"],
    "antigravity": [".agents", "GEMINI.md"],
}

# Priority order for --first (most specific to least)
PRIORITY = [
    "opencode",
    "claude",
    "codex",
    "cursor",
    "copilot",
    "windsurf",
    "antigravity",
]


def load_markers_from_platforms_json() -> dict[str, list[str]] | None:
    """Try to load detect_markers from platforms.json in the SKILL_builder repo."""
    # Walk up from this script to find platforms.json
    current = Path(__file__).resolve().parent
    for _ in range(10):
        candidate = current / "platforms.json"
        if candidate.exists():
            try:
                with open(candidate, "r", encoding="utf-8") as f:
                    data = json.load(f)
                platforms = data.get("platforms", {})
                return {
                    name: cfg.get("detect_markers", [])
                    for name, cfg in platforms.items()
                    if name != "universal" and cfg.get("detect_markers")
                }
            except (json.JSONDecodeError, OSError):
                return None
        current = current.parent
    return None


def detect_platforms(target: Path) -> list[dict]:
    """Detect active platforms in target directory."""
    markers = load_markers_from_platforms_json() or FALLBACK_MARKERS

    detected = []
    for platform in PRIORITY:
        platform_markers = markers.get(platform, [])
        found = []
        for marker in platform_markers:
            marker_path = target / marker
            if marker_path.exists():
                found.append(marker)
        if found:
            detected.append(
                {
                    "platform": platform,
                    "markers_found": found,
                    "markers_checked": platform_markers,
                }
            )

    return detected


def main():
    parser = argparse.ArgumentParser(description="PEtFiSh — Platform Detection")
    parser.add_argument(
        "--target", type=str, default=".", help="Target project path (default: .)"
    )
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    parser.add_argument(
        "--first",
        action="store_true",
        help="Output only the first (highest priority) detected platform name",
    )
    args = parser.parse_args()

    target = Path(args.target).resolve()
    if not target.exists():
        print(f"Target path does not exist: {target}", file=sys.stderr)
        sys.exit(1)

    detected = detect_platforms(target)

    if args.first:
        if detected:
            print(detected[0]["platform"])
        else:
            print("unknown")
        sys.exit(0)

    if args.json:
        print(
            json.dumps(
                {"target": str(target), "detected": detected},
                ensure_ascii=False,
                indent=2,
            )
        )
        sys.exit(0)

    if not detected:
        print(f"No AI coding platform detected in {target}")
        print("Checked markers for: " + ", ".join(PRIORITY))
        sys.exit(0)

    print(f"Detected platform(s) in {target}:\n")
    for d in detected:
        markers_str = ", ".join(d["markers_found"])
        print(f"  ✅ {d['platform'].ljust(14)} (found: {markers_str})")

    if len(detected) > 1:
        print(f"\nPrimary (highest priority): {detected[0]['platform']}")


if __name__ == "__main__":
    main()
