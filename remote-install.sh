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
