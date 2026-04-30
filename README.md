# 胖鱼 petfish — SKILL_builder

OpenCode skill packs — build, maintain, and install custom skills into any project.

Supports both **OpenCode** and **Google Antigravity** platforms.

## Packs

| Alias | Pack | Skills | Commands | Agents | Default Install |
|-------|------|--------|----------|--------|----------------|
| `init` | project-initializer-skill | 1 | 1 | 0 | **Global** |
| `course` | opencode-course-skills-pack | 15 | 10 | 8 | Project |
| `testdocs` | opencode-skill-pack-testcases-usage-docs | 2 | 0 | 0 | Project |
| `deploy` | repo-deploy-ops-skill-pack | 7 | 0 | 0 | Project |
| `petfish` | petfish-style-skill | 1 | 0 | 0 | Project |
| `ppt` | opencode-ppt-skills | 2 | 0 | 0 | Project |

## Install

### Platform Support

| Platform | `--platform` value | Skills dir (project) | Skills dir (global) |
|----------|-------------------|---------------------|---------------------|
| OpenCode | `opencode` (default) | `.opencode/skills/` | `~/.config/opencode/skills/` |
| Antigravity | `antigravity` | `.agents/skills/` | `~/.gemini/antigravity/skills/` |
| Both | `all` | Both paths | Both paths |

Antigravity mode additionally creates `GEMINI.md` (same content as `AGENTS.md`) and skips `opencode.json` merge.

### Global vs Project Install

- **Global install** (`--global`): Installs skills to user-level directory. Skips AGENTS.md merge, opencode.json merge, and registry updates. Best for skills that should be available across all projects (e.g. `init`).
- **Project install** (default): Installs to the target project's `.opencode/` or `.agents/` directory with full merge support.

The `init` pack **defaults to global** install. Use `--target <path>` to override to project-local.

### One-liner (remote — no clone needed)

**Bash (macOS/Linux/WSL):**

```bash
# Install project initializer globally (default)
curl -fsSL https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.sh | bash -s -- --pack init
# Install course pack to current project
curl -fsSL https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.sh | bash -s -- --pack course
# Install all packs for Antigravity
curl -fsSL https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.sh | bash -s -- --pack all --platform antigravity
# Install to specific target
curl -fsSL https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.sh | bash -s -- --pack petfish --platform all --target ~/my-project
```

**PowerShell (Windows):**

```powershell
# Install project initializer globally (default)
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.ps1))) -Pack init
# Install course pack to current project
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.ps1))) -Pack course
# Install all packs for Antigravity
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.ps1))) -Pack all -Platform antigravity
# Install to specific target
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.ps1))) -Pack petfish -Platform all -Target .
```

**Private repos** — pass a token:

```bash
curl -fsSL -H "Authorization: token $GITHUB_TOKEN" \
  https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.sh \
  | GITHUB_TOKEN=$GITHUB_TOKEN bash -s -- --pack course
```

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.ps1))) -Pack course -GitHubToken $env:GITHUB_TOKEN
```

### Local (if you've cloned the repo)

#### PowerShell (Windows)

```powershell
.\install.ps1 -Pack init                              # global install (default for init)
.\install.ps1 -Pack course -Target C:\path\to\project  # project install
.\install.ps1 -Pack all -Platform antigravity           # all packs for Antigravity
.\install.ps1 -Pack petfish -Platform all -Force        # both platforms, force overwrite
.\install.ps1 -Pack deploy -Global                      # any pack can be installed globally
.\install.ps1 -List
```

#### Bash (macOS/Linux/WSL)

```bash
./install.sh --pack init                                # global install (default for init)
./install.sh --pack course --target ~/my-project        # project install
./install.sh --pack all --platform antigravity           # all packs for Antigravity
./install.sh --pack petfish --platform all --force       # both platforms, force overwrite
./install.sh --pack deploy --global                     # any pack can be installed globally
./install.sh --list
```

## Antigravity Quick Start (Windows)

Install project initializer globally, then install all packs for Antigravity:

```powershell
# Step 1: Install the project initializer globally
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.ps1))) -Pack init -Platform antigravity

# Step 2: Install all packs into your project
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.ps1))) -Pack all -Platform antigravity
```

Install a single pack:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.ps1))) -Pack petfish -Platform antigravity
```

Specify target project and force overwrite:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.ps1))) -Pack all -Platform antigravity -Target C:\path\to\project -Force
```

Install for both OpenCode and Antigravity simultaneously:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.ps1))) -Pack all -Platform all
```

After installation, the target project will have:

```
your-project/
├── .agents/
│   ├── skills/                ← Skill files (SKILL.md format, identical to OpenCode)
│   ├── rules/                 ← Agent rules (maps from .opencode/agents/)
│   ├── workflows/             ← Workflows (maps from .opencode/commands/)
│   └── installed-packs.json   ← Install registry
├── AGENTS.md                  ← Project instructions (marker-based merge)
└── GEMINI.md                  ← Copy of AGENTS.md (Antigravity-specific)
```

Global skills live at:

```
~/.config/opencode/skills/       ← OpenCode global skills
~/.gemini/antigravity/skills/    ← Antigravity global skills
```

## Prerequisites

- **uv** (recommended): Required for Python-based skills. Install from https://docs.astral.sh/uv/getting-started/installation/
- The installer will warn if uv is not found.

## Adding a New Pack

1. Create a directory under `packs/` with your pack name
2. Add a `.opencode/` directory containing `skills/`, `commands/`, and/or `agents/`
3. Optionally add a `pack-manifest.json` for metadata
4. If the pack includes an `AGENTS.md`, it will be copied to the target project root during install (skipped if one already exists unless `--force` is used)
5. If the pack includes an `opencode.example.json`, the installer will deep-merge it into the target's `opencode.json`
6. The install scripts will pick it up automatically — add an alias in the scripts if you want a short name

## Structure

```
SKILL_builder/
├── packs/
│   ├── project-initializer-skill/    ← Global-default pack
│   │   └── .opencode/
│   │       └── skills/       (1 skill)
│   ├── opencode-course-skills-pack/
│   │   ├── .opencode/
│   │   │   ├── skills/       (15 skills)
│   │   │   ├── commands/     (10 commands)
│   │   │   └── agents/       (8 agents)
│   │   └── pack-manifest.json
│   ├── opencode-skill-pack-testcases-usage-docs/
│   │   └── .opencode/
│   │       └── skills/       (2 skills)
│   ├── repo-deploy-ops-skill-pack/
│   │   └── .opencode/
│   │       └── skills/       (7 skills)
│   ├── petfish-style-skill/
│   │   ├── .opencode/
│   │   │   └── skills/       (1 skill)
│   │   ├── AGENTS.md
│   │   └── opencode.example.json
│   └── opencode-ppt-skills/
│       ├── .opencode/
│       │   └── skills/       (2 skills)
│       ├── pack-manifest.json
│       └── opencode.example.json
├── install.ps1
├── install.sh
├── remote-install.ps1
├── remote-install.sh
└── README.md
```
