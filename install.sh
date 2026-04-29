#!/usr/bin/env bash
#
# Install OpenCode skill packs into a target project.
#
# Usage:
#   ./install.sh --pack course --target ~/my-project
#   ./install.sh --pack all
#   ./install.sh --list
#   ./install.sh --pack testdocs --force
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKS_DIR="$SCRIPT_DIR/packs"

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
        # Replace existing section using python for reliable multiline regex
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

    # Append
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
    [ppt]="opencode-ppt-skills"
)

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
        -h|--help)
            echo "Usage: $0 --pack <name|all> [--target <path>] [--force] [--list]"
            echo "Aliases: course, testdocs, deploy, petfish, ppt"
            exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

resolve_pack() {
    local name="$1"
    if [[ -n "${ALIASES[$name]+x}" ]]; then
        echo "${ALIASES[$name]}"
    elif [[ -d "$PACKS_DIR/$name" ]]; then
        echo "$name"
    else
        echo "Unknown pack: '$name'. Use --list to see available packs." >&2
        exit 1
    fi
}

get_all_packs() {
    find "$PACKS_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}

show_list() {
    echo ""
    echo "Available packs:"
    echo "$(printf '%.0s-' {1..60})"
    for dir in $(get_all_packs); do
        alias=""
        for key in "${!ALIASES[@]}"; do
            if [[ "${ALIASES[$key]}" == "$dir" ]]; then
                alias=" (alias: $key)"
                break
            fi
        done
        echo "  $dir$alias"
    done
    echo ""
}

# --- List mode ---
if $LIST; then
    show_list
    exit 0
fi

if [[ -z "$PACK" ]]; then
    echo "Error: --pack required. Use --list to see available packs." >&2
    exit 1
fi

# --- Resolve target ---
TARGET="$(cd "$TARGET" && pwd)"
TARGET_OPENCODE="$TARGET/.opencode"

# --- Resolve packs ---
if [[ "$PACK" == "all" ]]; then
    mapfile -t PACKS < <(get_all_packs)
else
    PACKS=("$(resolve_pack "$PACK")")
fi

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
                ((skipped++))
                continue
            fi

            [[ -d "$dst_item" ]] && rm -rf "$dst_item"
            cp -r "$item" "$dst_item"
            echo "  + $subdir/$item_name"
            ((installed++))
        done
    done
done

echo ""
echo "Done: $installed installed, $skipped skipped."
