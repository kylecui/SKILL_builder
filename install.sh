#!/usr/bin/env bash
#
# Install petfish skill packs into a target project or global skills directory.
#
# Usage:
#   ./install.sh --pack course --target ~/my-project
#   ./install.sh --pack all --platform antigravity
#   ./install.sh --pack petfish --platform all
#   ./install.sh --pack init --global
#   ./install.sh --list
#   ./install.sh --pack testdocs --force
#
set -euo pipefail

# --- uv availability check ---
if ! command -v uv &>/dev/null; then
    echo "[petfish] WARNING: uv not found. Some skill packs require uv to run Python scripts."
    echo "         Install: https://docs.astral.sh/uv/getting-started/installation/"
fi

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
    local registry_dir="$1" pack_name="$2" manifest_file="$3"
    local reg_file="$registry_dir/installed-packs.json"

    mkdir -p "$registry_dir"

    python3 -c "
import json, sys, os
from datetime import datetime, timezone

registry_dir = sys.argv[1]
pack_name = sys.argv[2]
manifest_file = sys.argv[3]
reg_file = os.path.join(registry_dir, 'installed-packs.json')

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
" "$registry_dir" "$pack_name" "$manifest_file"
}

# --- Pack alias registry ---
declare -A ALIASES=(
    [course]="opencode-course-skills-pack"
    [testdocs]="opencode-skill-pack-testcases-usage-docs"
    [deploy]="repo-deploy-ops-skill-pack"
    [petfish]="petfish-style-skill"
    [ppt]="opencode-ppt-skills"
    [init]="project-initializer-skill"
)

# --- Defaults ---
PACK=""
TARGET="."
TARGET_EXPLICIT=false
PLATFORM="opencode"
FORCE=false
LIST=false
GLOBAL=false

# --- Parse args ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --pack)     PACK="$2"; shift 2 ;;
        --target)   TARGET="$2"; TARGET_EXPLICIT=true; shift 2 ;;
        --platform) PLATFORM="$2"; shift 2 ;;
        --global)   GLOBAL=true; shift ;;
        --force)    FORCE=true; shift ;;
        --list)     LIST=true; shift ;;
        -h|--help)
            echo "Usage: $0 --pack <name|all> [--target <path>] [--platform <opencode|antigravity|all>] [--global] [--force] [--list]"
            echo "胖鱼 PEtFiSh Self-adaptive Skill Installer"
            echo "Aliases: course, testdocs, deploy, petfish, ppt, init"
            exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# Validate platform
case "$PLATFORM" in
    opencode|antigravity|all) ;;
    *) echo "Error: --platform must be opencode, antigravity, or all" >&2; exit 1 ;;
esac

if ! $LIST; then
    echo ""
    echo "  [胖鱼 PEtFiSh] Self-adaptive Skill Installer"
    echo ""
fi

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

# --- Platform path config ---
get_skills_dir() {
    case "$1" in
        opencode)     echo ".opencode/skills" ;;
        antigravity)  echo ".agents/skills" ;;
    esac
}

get_global_skills_dir() {
    case "$1" in
        opencode)     echo "$HOME/.config/opencode/skills" ;;
        antigravity)  echo "$HOME/.gemini/antigravity/skills" ;;
    esac
}

get_global_commands_dir() {
    case "$1" in
        opencode)     echo "$HOME/.config/opencode/commands" ;;
        antigravity)  echo "$HOME/.gemini/antigravity/workflows" ;;
    esac
}

get_agents_dir() {
    case "$1" in
        opencode)     echo ".opencode/agents" ;;
        antigravity)  echo ".agents/rules" ;;
    esac
}

get_commands_dir() {
    case "$1" in
        opencode)     echo ".opencode/commands" ;;
        antigravity)  echo ".agents/workflows" ;;
    esac
}

get_registry_dir() {
    case "$1" in
        opencode)     echo ".opencode" ;;
        antigravity)  echo ".agents" ;;
    esac
}

should_merge_json() {
    [[ "$1" == "opencode" ]]
}

should_create_gemini() {
    [[ "$1" == "antigravity" ]]
}

# --- Install function for a given platform ---
install_for_platform() {
    local platform_name="$1"
    shift
    local -a packs=("$@")

    local skills_dir
    skills_dir="$(get_skills_dir "$platform_name")"
    local agents_dir
    agents_dir="$(get_agents_dir "$platform_name")"
    local commands_dir
    commands_dir="$(get_commands_dir "$platform_name")"
    local registry_dir
    registry_dir="$(get_registry_dir "$platform_name")"

    echo ""
    echo "[$platform_name] Installing..."

    local installed=0
    local skipped=0

    for pack_name in "${packs[@]}"; do
        local pack_opencode="$PACKS_DIR/$pack_name/.opencode"
        if [[ ! -d "$pack_opencode" ]]; then
            echo "WARN: Pack '$pack_name' has no .opencode/ directory. Skipping."
            continue
        fi

        echo ""
        echo "  Installing pack: $pack_name"

        local pack_root="$PACKS_DIR/$pack_name"

        # --- Merge AGENTS.md ---
        if [[ -f "$pack_root/AGENTS.md" ]]; then
            local dst_agents="$TARGET/AGENTS.md"
            local result
            result="$(merge_agents_md "$pack_root/AGENTS.md" "$dst_agents" "$pack_name" "$FORCE")"
            case "$result" in
                created) echo "    + AGENTS.md (created)"; ((installed++)) || true ;;
                merged)  echo "    + AGENTS.md (merged)";  ((installed++)) || true ;;
                updated) echo "    + AGENTS.md (updated)"; ((installed++)) || true ;;
                exists)  echo "    SKIP AGENTS.md (pack section exists, use --force to update)"; ((skipped++)) || true ;;
            esac

            # Antigravity: also create/merge GEMINI.md
            if should_create_gemini "$platform_name"; then
                local dst_gemini="$TARGET/GEMINI.md"
                result="$(merge_agents_md "$pack_root/AGENTS.md" "$dst_gemini" "$pack_name" "$FORCE")"
                case "$result" in
                    created) echo "    + GEMINI.md (created)"; ((installed++)) || true ;;
                    merged)  echo "    + GEMINI.md (merged)";  ((installed++)) || true ;;
                    updated) echo "    + GEMINI.md (updated)"; ((installed++)) || true ;;
                    exists)  echo "    SKIP GEMINI.md (pack section exists, use --force to update)"; ((skipped++)) || true ;;
                esac
            fi
        fi

        # --- Merge opencode.json (OpenCode only) ---
        if should_merge_json "$platform_name"; then
            if [[ -f "$pack_root/opencode.example.json" ]]; then
                local dst_oc="$TARGET/opencode.json"
                result="$(merge_opencode_json "$pack_root/opencode.example.json" "$dst_oc" "$FORCE")"
                case "$result" in
                    created) echo "    + opencode.json (created from example)"; ((installed++)) || true ;;
                    merged)  echo "    + opencode.json (merged)";              ((installed++)) || true ;;
                esac
            fi
        fi

        # --- Update installed-packs registry ---
        local target_registry="$TARGET/$registry_dir"
        update_installed_packs "$target_registry" "$pack_name" "$pack_root/pack-manifest.json"
        echo "    + $registry_dir/installed-packs.json (registry updated)"

        # --- Copy skills ---
        local src_skills="$pack_opencode/skills"
        if [[ -d "$src_skills" ]]; then
            local target_skills="$TARGET/$skills_dir"
            mkdir -p "$target_skills"
            for item in "$src_skills"/*/; do
                [[ -d "$item" ]] || continue
                local item_name
                item_name="$(basename "$item")"
                local dst_item="$target_skills/$item_name"

                if [[ -d "$dst_item" ]] && ! $FORCE; then
                    echo "    SKIP skills/$item_name (exists, use --force to overwrite)"
                    ((skipped++)) || true
                    continue
                fi
                [[ -d "$dst_item" ]] && rm -rf "$dst_item"
                cp -r "$item" "$dst_item"
                echo "    + skills/$item_name"
                ((installed++)) || true
            done
        fi

        # --- Copy agents ---
        local src_agents="$pack_opencode/agents"
        if [[ -d "$src_agents" ]]; then
            local target_agents="$TARGET/$agents_dir"
            mkdir -p "$target_agents"
            for item in "$src_agents"/*/; do
                [[ -d "$item" ]] || continue
                local item_name
                item_name="$(basename "$item")"
                local dst_item="$target_agents/$item_name"

                if [[ -d "$dst_item" ]] && ! $FORCE; then
                    echo "    SKIP agents/$item_name (exists, use --force to overwrite)"
                    ((skipped++)) || true
                    continue
                fi
                [[ -d "$dst_item" ]] && rm -rf "$dst_item"
                cp -r "$item" "$dst_item"
                echo "    + agents/$item_name"
                ((installed++)) || true
            done
        fi

        # --- Copy commands ---
        local src_commands="$pack_opencode/commands"
        if [[ -d "$src_commands" ]]; then
            local target_commands="$TARGET/$commands_dir"
            mkdir -p "$target_commands"
            for item in "$src_commands"/*/; do
                [[ -d "$item" ]] || continue
                local item_name
                item_name="$(basename "$item")"
                local dst_item="$target_commands/$item_name"

                if [[ -d "$dst_item" ]] && ! $FORCE; then
                    echo "    SKIP commands/$item_name (exists, use --force to overwrite)"
                    ((skipped++)) || true
                    continue
                fi
                [[ -d "$dst_item" ]] && rm -rf "$dst_item"
                cp -r "$item" "$dst_item"
                echo "    + commands/$item_name"
                ((installed++)) || true
            done
        fi
    done

    echo ""
    echo "  [$platform_name] Done: $installed installed, $skipped skipped."
}

install_global_for_platform() {
    local platform_name="$1"
    shift
    local -a packs=("$@")

    local global_skills_dir
    global_skills_dir="$(get_global_skills_dir "$platform_name")"

    echo ""
    echo "[$platform_name] Global install -> $global_skills_dir"
    echo "  Skills only; skipping AGENTS.md, opencode.json, and registry."

    local installed=0
    local skipped=0

    mkdir -p "$global_skills_dir"

    for pack_name in "${packs[@]}"; do
        local pack_opencode="$PACKS_DIR/$pack_name/.opencode"
        local src_skills="$pack_opencode/skills"

        if [[ ! -d "$src_skills" ]]; then
            echo "WARN: Pack '$pack_name' has no .opencode/skills directory. Skipping."
            continue
        fi

        echo ""
        echo "  Installing pack globally: $pack_name"

        for item in "$src_skills"/*/; do
            [[ -d "$item" ]] || continue
            local item_name
            item_name="$(basename "$item")"
            local dst_item="$global_skills_dir/$item_name"

            if [[ -d "$dst_item" ]] && ! $FORCE; then
                echo "    SKIP skills/$item_name (exists in global dir, use --force to overwrite)"
                ((skipped++)) || true
                continue
            fi
            [[ -d "$dst_item" ]] && rm -rf "$dst_item"
            cp -r "$item" "$dst_item"
            echo "    + skills/$item_name"
            ((installed++)) || true
        done

        # --- Copy commands to global commands dir ---
        local src_commands="$pack_opencode/commands"
        if [[ -d "$src_commands" ]]; then
            local global_commands_dir
            global_commands_dir="$(get_global_commands_dir "$platform_name")"
            mkdir -p "$global_commands_dir"
            for item in "$src_commands"/*; do
                [[ -e "$item" ]] || continue
                local item_name
                item_name="$(basename "$item")"
                local dst_item="$global_commands_dir/$item_name"

                if [[ -e "$dst_item" ]] && ! $FORCE; then
                    echo "    SKIP commands/$item_name (exists in global dir, use --force to overwrite)"
                    ((skipped++)) || true
                    continue
                fi
                if [[ -d "$item" ]]; then
                    [[ -d "$dst_item" ]] && rm -rf "$dst_item"
                    cp -r "$item" "$dst_item"
                else
                    cp -f "$item" "$dst_item"
                fi
                echo "    + commands/$item_name"
                ((installed++)) || true
            done
        fi
    done

    echo ""
    echo "  [$platform_name] Global done: $installed installed, $skipped skipped."
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

# --- Resolve packs ---
if [[ "$PACK" == "all" ]]; then
    mapfile -t PACKS < <(get_all_packs)
else
    PACKS=("$(resolve_pack "$PACK")")
fi

if [[ "$PACK" == "init" || "$PACK" == "project-initializer-skill" ]] && ! $GLOBAL && ! $TARGET_EXPLICIT && [[ "$TARGET" == "." ]]; then
    GLOBAL=true
    echo "  [info] init pack defaults to global install. Use --target to install locally."
fi

# --- Resolve target ---
if ! $GLOBAL; then
    TARGET="$(cd "$TARGET" && pwd)"
fi

declare -a PLATFORMS
if [[ "$PLATFORM" == "all" ]]; then
    PLATFORMS=("opencode" "antigravity")
else
    PLATFORMS=("$PLATFORM")
fi

# --- Install for selected platform(s) ---
if $GLOBAL; then
    for platform_name in "${PLATFORMS[@]}"; do
        install_global_for_platform "$platform_name" "${PACKS[@]}"
    done
    exit 0
fi

for platform_name in "${PLATFORMS[@]}"; do
    install_for_platform "$platform_name" "${PACKS[@]}"
done
