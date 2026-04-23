# SKILL_builder

OpenCode skill packs — build, maintain, and install custom skills into any project.

## Packs

| Alias | Pack | Skills | Commands | Agents |
|-------|------|--------|----------|--------|
| `course` | opencode-course-skills-pack | 15 | 10 | 8 |
| `testdocs` | opencode-skill-pack-testcases-usage-docs | 2 | 0 | 0 |

## Install

### PowerShell (Windows)

```powershell
# Install a specific pack
.\install.ps1 -Pack course -Target C:\path\to\project

# Install all packs into current directory
.\install.ps1 -Pack all

# Overwrite existing skills
.\install.ps1 -Pack course -Target . -Force

# List available packs
.\install.ps1 -List
```

### Bash (macOS / Linux / WSL)

```bash
# Install a specific pack
./install.sh --pack course --target ~/my-project

# Install all packs into current directory
./install.sh --pack all

# Overwrite existing skills
./install.sh --pack testdocs --target . --force

# List available packs
./install.sh --list
```

### One-liner (local)

```powershell
# PowerShell — install all packs into current project
& D:\MyWorkSpaces\SKILL_builder\install.ps1 -Pack all -Target .
```

```bash
# Bash — install all packs into current project
bash /path/to/SKILL_builder/install.sh --pack all --target .
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
│   └── opencode-skill-pack-testcases-usage-docs/
│       └── .opencode/
│           └── skills/       (2 skills)
├── install.ps1
├── install.sh
└── README.md
```
