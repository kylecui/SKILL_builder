# SKILL_builder

OpenCode skill packs — build, maintain, and install custom skills into any project.

## Packs

| Alias | Pack | Skills | Commands | Agents |
|-------|------|--------|----------|--------|
| `course` | opencode-course-skills-pack | 15 | 10 | 8 |
| `testdocs` | opencode-skill-pack-testcases-usage-docs | 2 | 0 | 0 |
| `deploy` | repo-deploy-ops-skill-pack | 7 | 0 | 0 |

## Install

### One-liner (remote — no clone needed)

**Bash (macOS / Linux / WSL):**

```bash
curl -fsSL https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.sh | bash -s -- --pack course
curl -fsSL https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.sh | bash -s -- --pack all --target ~/my-project
curl -fsSL https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.sh | bash -s -- --pack testdocs --force
```

**PowerShell (Windows):**

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.ps1))) -Pack course
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.ps1))) -Pack all -Target .
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.ps1))) -Pack testdocs -Force
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
.\install.ps1 -Pack all
.\install.ps1 -Pack course -Target . -Force
.\install.ps1 -List
```

#### Bash (macOS / Linux / WSL)

```bash
./install.sh --pack course --target ~/my-project
./install.sh --pack all
./install.sh --pack testdocs --target . --force
./install.sh --list
```

## Adding a New Pack

1. Create a directory under `packs/` with your pack name
2. Add a `.opencode/` directory containing `skills/`, `commands/`, and/or `agents/`
3. Optionally add a `pack-manifest.json` for metadata
4. The install scripts will pick it up automatically — add an alias in the scripts if you want a short name

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
├── install.ps1
├── install.sh
├── remote-install.ps1
├── remote-install.sh
└── README.md
```
