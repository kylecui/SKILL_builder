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

# --- Pack alias registry ---
declare -A ALIASES=(
    [course]="opencode-course-skills-pack"
    [testdocs]="opencode-skill-pack-testcases-usage-docs"
    [deploy]="repo-deploy-ops-skill-pack"
    [kyle]="kyle-style-skill"
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
            echo "Aliases: course, testdocs, deploy, kyle"
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

    # --- Copy root-level AGENTS.md if present ---
    if [[ -f "$pack_root/AGENTS.md" ]]; then
        dst_agents="$TARGET/AGENTS.md"
        if [[ -f "$dst_agents" ]] && ! $FORCE; then
            echo "  SKIP AGENTS.md (exists, use --force to overwrite)"
            ((skipped++)) || true
        else
            cp "$pack_root/AGENTS.md" "$dst_agents"
            echo "  + AGENTS.md"
            ((installed++)) || true
        fi
    fi

    # --- Notify about opencode.example.json if present ---
    if [[ -f "$pack_root/opencode.example.json" ]]; then
        echo "  INFO: Pack includes opencode.example.json — merge into your opencode.json manually if needed."
    fi

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
