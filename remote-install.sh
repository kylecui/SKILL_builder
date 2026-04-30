#!/usr/bin/env bash
#
# petfish - Remote installer for OpenCode/Antigravity skill packs from GitHub.
#
# Usage (curl one-liner):
#   curl -fsSL https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.sh | bash -s -- --pack course
#   curl -fsSL https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.sh | bash -s -- --pack all --platform antigravity
#   curl -fsSL https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.sh | bash -s -- --pack petfish --platform all
#
# For private repos, set GITHUB_TOKEN:
#   curl -fsSL -H "Authorization: token $GITHUB_TOKEN" https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.sh | GITHUB_TOKEN=$GITHUB_TOKEN bash -s -- --pack course
#
set -euo pipefail

# --- uv availability check ---
if ! command -v uv &>/dev/null; then
    echo "[petfish] WARNING: uv not found. Some skill packs require uv to run Python scripts."
    echo "         Install: https://docs.astral.sh/uv/getting-started/installation/"
fi

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
ALL_PACKS=("opencode-course-skills-pack" "opencode-skill-pack-testcases-usage-docs" "repo-deploy-ops-skill-pack" "petfish-style-skill" "opencode-ppt-skills" "project-initializer-skill")

# --- Defaults ---
PACK=""
TARGET="."
PLATFORM="opencode"
FORCE=false
LIST=false
GLOBAL=false

# --- Parse args ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --pack)     PACK="$2"; shift 2 ;;
        --target)   TARGET="$2"; shift 2 ;;
        --platform) PLATFORM="$2"; shift 2 ;;
        --force)    FORCE=true; shift ;;
        --global)   GLOBAL=true; shift ;;
        --list)     LIST=true; shift ;;
        --repo)     REPO="$2"; shift 2 ;;
        --branch)   BRANCH="$2"; shift 2 ;;
        -h|--help)
            echo "Usage: curl ... | bash -s -- --pack <name|all> [--target <path>] [--platform <opencode|antigravity|all>] [--force] [--global]"
            echo ""
            echo "Options:"
            echo "  --pack <name|all>       Pack to install (course, testdocs, deploy, petfish, ppt, init, or all)"
            echo "  --target <path>         Target project directory (default: ., ignored with --global)"
            echo "  --platform <platform>   Target platform: opencode, antigravity, or all (default: opencode)"
            echo "  --force                 Overwrite existing skills"
            echo "  --global                Install skills to the global platform skills directory"
            echo "  --list                  List available packs"
            echo "  --repo <owner/repo>     Override GitHub repo (default: $REPO)"
            echo "  --branch <branch>       Override branch (default: $BRANCH)"
            exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

if ! $LIST; then
    echo ""
    echo "  [petfish] Skill Pack Installer (remote)"
    echo ""
fi

# Validate platform
case "$PLATFORM" in
    opencode|antigravity|all) ;;
    *) echo "Error: --platform must be opencode, antigravity, or all" >&2; exit 1 ;;
esac

# --- List mode ---
if $LIST; then
    echo ""
    echo "Available packs:"
    echo "------------------------------------------------------------"
    echo "  opencode-course-skills-pack (alias: course)"
    echo "  opencode-skill-pack-testcases-usage-docs (alias: testdocs)"
    echo "  repo-deploy-ops-skill-pack (alias: deploy)"
    echo "  petfish-style-skill (alias: petfish)"
    echo "  opencode-ppt-skills (alias: ppt)"
    echo "  project-initializer-skill (alias: init)"
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
        for p in "${ALL_PACKS[@]}"; do
            if [[ "$p" == "$name" ]]; then
                echo "$name"
                return
            fi
        done
        echo "Unknown pack: '$name'. Available: course, testdocs, deploy, petfish, ppt, init, all" >&2
        exit 1
    fi
}

if [[ "$PACK" == "all" ]]; then
    PACKS=("${ALL_PACKS[@]}")
else
    PACKS=("$(resolve_pack "$PACK")")
fi

if [[ "${PACKS[0]}" == "project-initializer-skill" ]] && ! $GLOBAL && [[ "$TARGET" == "." ]]; then
    GLOBAL=true
    echo "[petfish] INFO: init defaults to global install when --target is unchanged; enabling --global."
fi

# --- Resolve target ---
if ! $GLOBAL; then
    mkdir -p "$TARGET"
    TARGET="$(cd "$TARGET" && pwd)"
fi

# --- Platform path helpers ---
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

# --- Install function for a given platform ---
install_for_platform() {
    local platform_name="$1"

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

    if $GLOBAL; then
        local global_skills_dir
        global_skills_dir="$(get_global_skills_dir "$platform_name")"
        echo "  Global install enabled: $global_skills_dir"
        mkdir -p "$global_skills_dir"
    fi

    local installed=0
    local skipped=0

    for pack_name in "${PACKS[@]}"; do
        local pack_opencode="$PACKS_DIR/$pack_name/.opencode"
        if [[ ! -d "$pack_opencode" ]]; then
            echo "WARN: Pack '$pack_name' has no .opencode/ directory. Skipping."
            continue
        fi

        echo ""
        echo "  Installing pack: $pack_name"

        local pack_root="$PACKS_DIR/$pack_name"

        if $GLOBAL; then
            echo "    Copying skills to global directory..."

            local src_skills="$pack_opencode/skills"
            local global_skills_dir
            global_skills_dir="$(get_global_skills_dir "$platform_name")"

            if [[ -d "$src_skills" ]]; then
                for item in "$src_skills"/*/; do
                    [[ -d "$item" ]] || continue
                    local item_name
                    item_name="$(basename "$item")"
                    local dst_item="$global_skills_dir/$item_name"

                    if [[ -d "$dst_item" ]] && ! $FORCE; then
                        echo "    SKIP global skills/$item_name (exists, use --force to overwrite)"
                        ((skipped++)) || true
                        continue
                    fi
                    [[ -d "$dst_item" ]] && rm -rf "$dst_item"
                    cp -r "$item" "$dst_item"
                    echo "    + global skills/$item_name -> $global_skills_dir"
                    ((installed++)) || true
                done
            else
                echo "    WARN: Pack '$pack_name' has no .opencode/skills/ directory. Skipping."
            fi

            echo "    SKIP project files (AGENTS.md, opencode.json, registry) for global install"
            continue
        fi

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

# --- Install for selected platform(s) ---
if [[ "$PLATFORM" == "all" ]]; then
    install_for_platform "opencode"
    install_for_platform "antigravity"
else
    install_for_platform "$PLATFORM"
fi
