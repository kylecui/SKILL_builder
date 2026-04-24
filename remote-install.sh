#!/usr/bin/env bash
#
# Remote installer for OpenCode skill packs from GitHub.
#
# Usage (curl one-liner):
#   curl -fsSL https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.sh | bash -s -- --pack course
#   curl -fsSL https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.sh | bash -s -- --pack all --target ~/my-project
#   curl -fsSL https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.sh | bash -s -- --pack testdocs --force
#
# For private repos, set GITHUB_TOKEN:
#   curl -fsSL -H "Authorization: token $GITHUB_TOKEN" https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.sh | GITHUB_TOKEN=$GITHUB_TOKEN bash -s -- --pack course
#
set -euo pipefail

REPO="kylecui/SKILL_builder"
BRANCH="master"

# --- Merge helpers ---

merge_agents_md() {
    local src_file="$1" dst_file="$2" pack_name="$3" force="$4"
    local begin_marker="<!-- BEGIN pack: $pack_name -->"
    local end_marker="<!-- END pack: $pack_name -->"
    local src_content
    src_content="$(cat "$src_file")"
    local wrapped="${begin_marker}
${src_content}
${end_marker}"

    if [[ ! -f "$dst_file" ]]; then
        printf '%s\n' "$wrapped" > "$dst_file"
        echo "created"
        return
    fi

    local existing
    existing="$(cat "$dst_file")"
    if echo "$existing" | grep -qF "$begin_marker"; then
        if ! $force; then
            echo "exists"
            return
        fi
        python3 -c "
import re, sys
begin = sys.argv[1]
end = sys.argv[2]
replacement = sys.argv[3]
text = open(sys.argv[4], 'r', encoding='utf-8').read()
pattern = re.escape(begin) + r'.*?' + re.escape(end)
result = re.sub(pattern, replacement, text, flags=re.DOTALL)
open(sys.argv[4], 'w', encoding='utf-8').write(result)
" "$begin_marker" "$end_marker" "$wrapped" "$dst_file"
        echo "updated"
        return
    fi

    printf '\n\n%s\n' "$wrapped" >> "$dst_file"
    echo "merged"
}

merge_opencode_json() {
    local src_file="$1" dst_file="$2" force="$3"

    if [[ ! -f "$dst_file" ]]; then
        cp "$src_file" "$dst_file"
        echo "created"
        return
    fi

    python3 -c "
import json, sys

force = sys.argv[3] == 'true'
with open(sys.argv[1], 'r') as f:
    src = json.load(f)
with open(sys.argv[2], 'r') as f:
    dst = json.load(f)

def deep_merge(s, d, force_flag):
    for k, v in s.items():
        if k not in d:
            d[k] = v
        elif isinstance(v, dict) and isinstance(d[k], dict):
            deep_merge(v, d[k], force_flag)
        elif force_flag:
            d[k] = v

deep_merge(src, dst, force)
with open(sys.argv[2], 'w') as f:
    json.dump(dst, f, indent=2, ensure_ascii=False)
    f.write('\n')
" "$src_file" "$dst_file" "$force"
    echo "merged"
}

update_installed_packs() {
    local target_opencode="$1" pack_name="$2" manifest_file="$3"
    local reg_file="$target_opencode/installed-packs.json"

    mkdir -p "$target_opencode"

    python3 -c "
import json, sys, os
from datetime import datetime, timezone

target_oc = sys.argv[1]
pack_name = sys.argv[2]
manifest_file = sys.argv[3]
reg_file = os.path.join(target_oc, 'installed-packs.json')

entry = {'installed_at': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')}

if os.path.isfile(manifest_file):
    with open(manifest_file, 'r') as f:
        m = json.load(f)
    for key in ('version', 'skills', 'description'):
        if key in m:
            entry[key] = m[key]

if os.path.isfile(reg_file):
    with open(reg_file, 'r') as f:
        reg = json.load(f)
else:
    reg = {'packs': {}}

reg['packs'][pack_name] = entry
with open(reg_file, 'w') as f:
    json.dump(reg, f, indent=2, ensure_ascii=False)
    f.write('\n')
" "$target_opencode" "$pack_name" "$manifest_file"
}

# --- Pack alias registry ---
declare -A ALIASES=(
    [course]="opencode-course-skills-pack"
    [testdocs]="opencode-skill-pack-testcases-usage-docs"
    [deploy]="repo-deploy-ops-skill-pack"
    [petfish]="petfish-style-skill"
)
ALL_PACKS=("opencode-course-skills-pack" "opencode-skill-pack-testcases-usage-docs" "repo-deploy-ops-skill-pack" "petfish-style-skill")

# --- Defaults ---
PACK=""
TARGET="."
FORCE=false
LIST=false

# --- Parse args ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --pack)   PACK="$2"; shift 2 ;;
        --target) TARGET="$2"; shift 2 ;;
        --force)  FORCE=true; shift ;;
        --list)   LIST=true; shift ;;
        --repo)   REPO="$2"; shift 2 ;;
        --branch) BRANCH="$2"; shift 2 ;;
        -h|--help)
            echo "Usage: curl ... | bash -s -- --pack <name|all> [--target <path>] [--force]"
            echo ""
            echo "Options:"
            echo "  --pack <name|all>   Pack to install (course, testdocs, deploy, petfish, or all)"
            echo "  --target <path>     Target project directory (default: .)"
            echo "  --force             Overwrite existing skills"
            echo "  --list              List available packs"
            echo "  --repo <owner/repo> Override GitHub repo (default: $REPO)"
            echo "  --branch <branch>   Override branch (default: $BRANCH)"
            exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# --- List mode ---
if $LIST; then
    echo ""
    echo "Available packs:"
    echo "------------------------------------------------------------"
    echo "  opencode-course-skills-pack (alias: course)"
    echo "  opencode-skill-pack-testcases-usage-docs (alias: testdocs)"
    echo "  repo-deploy-ops-skill-pack (alias: deploy)"
    echo "  petfish-style-skill (alias: petfish)"
    echo ""
    exit 0
fi

if [[ -z "$PACK" ]]; then
    echo "Error: --pack required. Use --list to see available packs." >&2
    echo "Example: curl -fsSL https://raw.githubusercontent.com/$REPO/$BRANCH/remote-install.sh | bash -s -- --pack course" >&2
    exit 1
fi

# --- Resolve pack names ---
resolve_pack() {
    local name="$1"
    if [[ -n "${ALIASES[$name]+x}" ]]; then
        echo "${ALIASES[$name]}"
    else
        # Check if it's already a full pack name
        for p in "${ALL_PACKS[@]}"; do
            if [[ "$p" == "$name" ]]; then
                echo "$name"
                return
            fi
        done
        echo "Unknown pack: '$name'. Available: course, testdocs, deploy, petfish, all" >&2
        exit 1
    fi
}

if [[ "$PACK" == "all" ]]; then
    PACKS=("${ALL_PACKS[@]}")
else
    PACKS=("$(resolve_pack "$PACK")")
fi

# --- Resolve target ---
mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"
TARGET_OPENCODE="$TARGET/.opencode"

# --- Download tarball ---
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

TARBALL_URL="https://github.com/$REPO/tarball/$BRANCH"
AUTH_HEADER=""
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    AUTH_HEADER="Authorization: token $GITHUB_TOKEN"
fi

echo "Downloading $REPO@$BRANCH..."
if [[ -n "$AUTH_HEADER" ]]; then
    curl -fsSL -H "$AUTH_HEADER" "$TARBALL_URL" | tar xz -C "$TMPDIR"
else
    curl -fsSL "$TARBALL_URL" | tar xz -C "$TMPDIR"
fi

# GitHub tarballs extract into <owner>-<repo>-<sha>/
EXTRACT_DIR="$(find "$TMPDIR" -mindepth 1 -maxdepth 1 -type d | head -1)"
if [[ -z "$EXTRACT_DIR" ]]; then
    echo "Error: failed to extract tarball" >&2
    exit 1
fi

PACKS_DIR="$EXTRACT_DIR/packs"

# --- Install ---
installed=0
skipped=0

for pack_name in "${PACKS[@]}"; do
    pack_opencode="$PACKS_DIR/$pack_name/.opencode"
    if [[ ! -d "$pack_opencode" ]]; then
        echo "WARN: Pack '$pack_name' has no .opencode/ directory. Skipping."
        continue
    fi

    echo ""
    echo "Installing pack: $pack_name"

    pack_root="$PACKS_DIR/$pack_name"

    # --- Merge AGENTS.md ---
    if [[ -f "$pack_root/AGENTS.md" ]]; then
        dst_agents="$TARGET/AGENTS.md"
        result="$(merge_agents_md "$pack_root/AGENTS.md" "$dst_agents" "$pack_name" "$FORCE")"
        case "$result" in
            created) echo "  + AGENTS.md (created)"; ((installed++)) || true ;;
            merged)  echo "  + AGENTS.md (merged)";  ((installed++)) || true ;;
            updated) echo "  + AGENTS.md (updated)"; ((installed++)) || true ;;
            exists)  echo "  SKIP AGENTS.md (pack section exists, use --force to update)"; ((skipped++)) || true ;;
        esac
    fi

    # --- Merge opencode.json from opencode.example.json ---
    if [[ -f "$pack_root/opencode.example.json" ]]; then
        dst_oc="$TARGET/opencode.json"
        result="$(merge_opencode_json "$pack_root/opencode.example.json" "$dst_oc" "$FORCE")"
        case "$result" in
            created) echo "  + opencode.json (created from example)"; ((installed++)) || true ;;
            merged)  echo "  + opencode.json (merged)";              ((installed++)) || true ;;
        esac
    fi

    # --- Update installed-packs registry ---
    update_installed_packs "$TARGET_OPENCODE" "$pack_name" "$pack_root/pack-manifest.json"
    echo "  + .opencode/installed-packs.json (registry updated)"

    for subdir in skills commands agents; do
        src_dir="$pack_opencode/$subdir"
        [[ -d "$src_dir" ]] || continue

        dst_dir="$TARGET_OPENCODE/$subdir"
        mkdir -p "$dst_dir"

        for item in "$src_dir"/*/; do
            [[ -d "$item" ]] || continue
            item_name="$(basename "$item")"
            dst_item="$dst_dir/$item_name"

            if [[ -d "$dst_item" ]] && ! $FORCE; then
                echo "  SKIP $subdir/$item_name (exists, use --force to overwrite)"
                ((skipped++)) || true
                continue
            fi

            [[ -d "$dst_item" ]] && rm -rf "$dst_item"
            cp -r "$item" "$dst_item"
            echo "  + $subdir/$item_name"
            ((installed++)) || true
        done
    done
done

echo ""
echo "Done: $installed installed, $skipped skipped."
