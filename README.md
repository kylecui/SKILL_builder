# SKILL_builder

OpenCode skill packs — build, maintain, and install custom skills into any project.

Supports both **OpenCode** and **Google Antigravity** platforms.

## Packs

| Alias | Pack | Skills | Commands | Agents |
|-------|------|--------|----------|--------|
| `course` | opencode-course-skills-pack | 15 | 10 | 8 |
| `testdocs` | opencode-skill-pack-testcases-usage-docs | 2 | 0 | 0 |
| `deploy` | repo-deploy-ops-skill-pack | 7 | 0 | 0 |
| `petfish` | petfish-style-skill | 1 | 0 | 0 |
| `ppt` | opencode-ppt-skills | 2 | 0 | 0 |

## Install

### Platform Support

| Platform | `--platform` value | Skills dir | Agents dir | Commands dir |
|----------|-------------------|------------|------------|--------------|
| OpenCode | `opencode` (default) | `.opencode/skills/` | `.opencode/agents/` | `.opencode/commands/` |
| Antigravity | `antigravity` | `.agents/skills/` | `.agents/rules/` | `.agents/workflows/` |
| Both | `all` | Both paths | Both paths | Both paths |

Antigravity mode additionally creates `GEMINI.md` (same content as `AGENTS.md`) and skips `opencode.json` merge.

### One-liner (remote — no clone needed)

**Bash (macOS / Linux / WSL):**

```bash
curl -fsSL https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.sh | bash -s -- --pack course
curl -fsSL https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.sh | bash -s -- --pack all --platform antigravity
curl -fsSL https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.sh | bash -s -- --pack petfish --platform all --target ~/my-project
```

**PowerShell (Windows):**

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.ps1))) -Pack course
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.ps1))) -Pack all -Platform antigravity
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
.\install.ps1 -Pack course -Target C:\path\to\project
.\install.ps1 -Pack all -Platform antigravity
.\install.ps1 -Pack petfish -Platform all -Force
.\install.ps1 -List
```

#### Bash (macOS / Linux / WSL)

```bash
./install.sh --pack course --target ~/my-project
./install.sh --pack all --platform antigravity
./install.sh --pack petfish --platform all --force
./install.sh --list
```

## Antigravity Quick Start (Windows)

Install all skill packs for Antigravity:

```powershell
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

## Adding a New Pack

1. Create a directory under `packs/` with your pack name
2. Add a `.opencode/` directory containing `skills/`, `commands/`, and/or `agents/`
3. Optionally add a `pack-manifest.json` for metadata
4. If the pack includes an `AGENTS.md`, it will be copied to the target project root during install (skipped if one already exists unless `--force` is used)
5. If the pack includes an `opencode.example.json`, the installer will remind the user to merge it manually
6. The install scripts will pick it up automatically — add an alias in the scripts if you want a short name

## Structure

```
SKILL_builder/
├── packs/
│   ├── opencode-course-skills-pack/
│   │   ├── .opencode/
│   │   │   ├── skills/       (15 skills)
│   │   │   ├── commands/     (10 commands)
│   │   │   └── agents/       (8 agents)
│   │   └── pack-manifest.json
│   ├── opencode-skill-pack-testcases-usage-docs/
│   │   └── .opencode/
│   │       └── skills/       (2 skills)
│   └── repo-deploy-ops-skill-pack/
│       └── .opencode/
│           └── skills/       (7 skills)
│   └── petfish-style-skill/
│       ├── .opencode/
│       │   └── skills/       (1 skill)
│       ├── AGENTS.md
│       └── opencode.example.json
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
