<p align="center">
  <img src="assets/petfish-logo.png" alt="胖鱼 PEtFiSh logo" width="360" />
</p>

# 胖鱼 PEtFiSh

**AI Worker's Companion — Self-adaptive skill installer for AI-assisted projects.**

Repo name: `SKILL_builder`  
Product name: `胖鱼 PEtFiSh`

胖鱼是AI工作者的伙伴。从项目第一天起，感知你在做什么、知道你还缺什么、帮你补齐能力。支持8个AI编程平台，一条命令完成skill安装。

PEtFiSh is your AI coding companion. It senses what you're working on, knows what skills you're missing, and equips you automatically. Supports 8 AI coding platforms with a single install command.

<p align="center">
  <img src="assets/petfish-icon-256.png" alt="胖鱼 PEtFiSh icon" width="128" />
</p>

## How It Works

```
┌─────────────────────────────────────────────────────┐
│  ><(((^>  胖鱼 PEtFiSh                             │
│                                                     │
│  1. Scaffold project structure (init_project.py)    │
│  2. Auto-install recommended skill packs            │
│  3. Post-init wizard (AGENTS.md, README, Git, ...)  │
│  4. Ready to work — skills available immediately    │
│                                                     │
│  /petfish — your always-on companion                │
│  Sense needs → Equip skills → Grow with you         │
└─────────────────────────────────────────────────────┘
```

## Quick Start

**One command to get started** — install the initializer globally, then use `/initproject` in any project:

```powershell
# Windows (PowerShell)
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.ps1))) -Pack init
```

```bash
# macOS / Linux / WSL
curl -fsSL https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.sh | bash -s -- --pack init
```

Then type `/initproject` — PEtFiSh will:
1. Ask your project type (code/course/ops/writing/comprehensive/...)
2. Create the project scaffold
3. Install matching skill packs automatically
4. Walk you through a setup wizard (each step skippable)

## Skill Packs

| Alias | Pack | Contents | Default |
|-------|------|----------|---------|
| `init` | project-initializer-skill | Initializer + wizard + `/initproject` command | **Global** |
| `companion` | petfish-companion-skill | `/petfish` command — sense needs, equip skills | **Global** |
| `course` | opencode-course-skills-pack | 15 skills, 10 commands, 8 agents | Project |
| `testdocs` | opencode-skill-pack-testcases-usage-docs | Test case & doc generation | Project |
| `deploy` | repo-deploy-ops-skill-pack | CI/CD, deploy, ops automation | Project |
| `petfish` | petfish-style-skill | 说人话 — engineering writing style | Project |
| `ppt` | opencode-ppt-skills | Slide design & presentation | Project |

### Profile → Auto-Install Mapping

When you use `/initproject`, PEtFiSh installs packs based on your project type:

| Profile | Auto-Installed Packs |
|---------|---------------------|
| minimal | petfish |
| course | course, petfish |
| code | deploy, petfish, testdocs |
| ops | deploy, petfish |
| security | deploy, petfish, testdocs |
| writing | petfish, ppt |
| skills-package | petfish, testdocs |
| comprehensive | course, deploy, petfish, ppt, testdocs |

## Platform Support

PEtFiSh supports 8 AI coding platforms. Platform configuration is driven by `platforms.json` — the single source of truth for all path conventions and instructions translation.

| Platform | `--platform` | Project Skills | Instructions File | Auto-Detect |
|----------|-------------|---------------|-------------------|-------------|
| OpenCode | `opencode` (default) | `.opencode/skills/` | `AGENTS.md` | `.opencode/`, `opencode.json` |
| Claude Code | `claude` | `.claude/skills/` | `CLAUDE.md` | `.claude/`, `CLAUDE.md` |
| Codex | `codex` | `.agents/skills/` | `AGENTS.md` | `.codex/` |
| Cursor | `cursor` | `.cursor/skills/` | `.cursor/rules/*.mdc` | `.cursor/`, `.cursorrules` |
| GitHub Copilot | `copilot` | `.github/skills/` | `.github/copilot-instructions.md` | `.github/copilot-instructions.md` |
| Windsurf | `windsurf` | `.windsurf/skills/` | `.windsurfrules` | `.windsurf/`, `.windsurfrules` |
| Antigravity | `antigravity` | `.agents/skills/` | `AGENTS.md` + `GEMINI.md` | `.agents/`, `GEMINI.md` |
| Universal | `universal` | `.agents/skills/` | `AGENTS.md` | (fallback) |

**Platform groups** for batch install:

| Group | Platforms |
|-------|----------|
| `all` | opencode, claude, codex, cursor, copilot, windsurf, antigravity |
| `primary` | opencode, claude, codex |
| `ide` | cursor, copilot, windsurf |
| `cli` | opencode, claude, codex, antigravity |

**Auto-detection**: Use `--detect` to let PEtFiSh determine the platform from project markers.

## Install Commands

### Remote (no clone needed)

```powershell
# PowerShell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.ps1))) -Pack <alias> [-Target .] [-Platform opencode] [-Detect] [-Force] [-Global]
```

```bash
# Bash
curl -fsSL https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.sh | bash -s -- --pack <alias> [--target .] [--platform opencode] [--detect] [--force] [--global]
```

### Local (cloned repo)

```powershell
.\install.ps1 -Pack <alias> [-Target path] [-Platform opencode|claude|codex|cursor|copilot|windsurf|antigravity|all|primary|ide|cli] [-Detect] [-Force] [-Global]
.\install.ps1 -List
```

```bash
./install.sh --pack <alias> [--target path] [--platform <platform|group>] [--detect] [--force] [--global]
./install.sh --list
```

### Private repos

```bash
curl -fsSL -H "Authorization: token $GITHUB_TOKEN" \
  https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.sh \
  | GITHUB_TOKEN=$GITHUB_TOKEN bash -s -- --pack course
```

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.ps1))) -Pack course -GitHubToken $env:GITHUB_TOKEN
```

### Cross-platform examples

```bash
# Install for Claude Code
./install.sh --pack deploy --platform claude --target ~/my-project

# Install for all primary platforms at once
./install.sh --pack petfish --platform primary --target ~/my-project

# Auto-detect platform and install
./install.sh --pack course --detect --target ~/my-project
```

## Companion: /petfish

The `companion` pack installs the `/petfish` command — your always-on AI skill assistant.

```
/petfish              → Show installed skill status
/petfish catalog      → Browse all available skills
/petfish search <kw>  → Search skills by keyword
/petfish suggest      → Get recommendations based on project structure
/petfish install <a>  → Get install command for a pack
/petfish detect       → Detect current platform
```

The companion **senses** your conversation context and proactively recommends skills when it detects a capability gap. For example, if you start discussing deployment but don't have the `deploy` pack installed, it will suggest installing it.

## Global vs Project Install

- **Global** (`--global`): Skills + commands installed to user-level directory. Available across all projects. The `init` and `companion` packs default to global.
- **Project** (default): Installed to target project's platform-specific directory with instructions merge, config merge, and registry tracking.

## Prerequisites

- **uv** (recommended): Required for Python-based skills. Install from https://docs.astral.sh/uv/getting-started/installation/
- **python3**: Required for platform config parsing and instructions translation.
- The installer warns if uv is not found.

## Adding a New Pack

1. Create a directory under `packs/` with your pack name
2. Add `.opencode/` containing `skills/`, `commands/`, and/or `agents/`
3. Add `pack-manifest.json` for metadata
4. Pack's `AGENTS.md` → marker-based merge into target project's instructions file
5. Pack's `opencode.example.json` → deep-merged into target's `opencode.json` (OpenCode only)
6. Add an alias in the install scripts and update `platforms.json` if needed

## Structure

```
SKILL_builder  # 胖鱼 PEtFiSh repo
├── packs/
│   ├── project-initializer-skill/    ← init (global-default)
│   ├── petfish-companion-skill/      ← companion (global-default)
│   ├── opencode-course-skills-pack/  ← course
│   ├── opencode-skill-pack-testcases-usage-docs/ ← testdocs
│   ├── repo-deploy-ops-skill-pack/   ← deploy
│   ├── petfish-style-skill/          ← petfish
│   └── opencode-ppt-skills/          ← ppt
├── platforms.json       ← Platform registry (single source of truth)
├── install.ps1          ← Local PowerShell installer
├── install.sh           ← Local Bash installer
├── remote-install.ps1   ← Remote PowerShell installer
├── remote-install.sh    ← Remote Bash installer
└── README.md
```

---

> **胖鱼 PEtFiSh** — AI工作者的伙伴，让每个项目从第一天就有正确的AI技能加持。
>
> Your AI coding companion — every project gets the right skills from day one.
