<#
.SYNOPSIS
    Remote installer for OpenCode skill packs from GitHub. No clone needed.

.DESCRIPTION
    Downloads the repo tarball, extracts the requested pack, and copies
    .opencode/skills/, commands/, agents/ into the target project.

.EXAMPLE
    # One-liner:
    irm https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.ps1 | iex
    # Then call the function:
    Install-SkillPack -Pack course

    # Or inline:
    & ([scriptblock]::Create((irm https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.ps1))) -Pack course -Target .
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Pack,
    [string]$Target = ".",
    [switch]$Force,
    [switch]$List,
    [string]$Repo = "kylecui/SKILL_builder",
    [string]$Branch = "master",
    [string]$GitHubToken
)

$ErrorActionPreference = "Stop"

# --- Pack alias registry ---
$Aliases = @{
    "course"   = "opencode-course-skills-pack"
    "testdocs" = "opencode-skill-pack-testcases-usage-docs"
    "deploy"   = "repo-deploy-ops-skill-pack"
    "petfish"  = "petfish-style-skill"
}
$AllPacks = @("opencode-course-skills-pack", "opencode-skill-pack-testcases-usage-docs", "repo-deploy-ops-skill-pack", "petfish-style-skill")

# --- List mode ---
if ($List) {
    Write-Host "`nAvailable packs:" -ForegroundColor Cyan
    Write-Host ("-" * 60)
    Write-Host "  opencode-course-skills-pack (alias: course)"
    Write-Host "  opencode-skill-pack-testcases-usage-docs (alias: testdocs)"
    Write-Host "  repo-deploy-ops-skill-pack (alias: deploy)"
    Write-Host "  petfish-style-skill (alias: petfish)"
    Write-Host ""
    return
}

# --- Resolve pack names ---
function Resolve-PackName([string]$name) {
    if ($Aliases.ContainsKey($name)) { return $Aliases[$name] }
    if ($AllPacks -contains $name) { return $name }
    Write-Error "Unknown pack: '$name'. Available: course, testdocs, deploy, petfish, all"
    exit 1
}

$packsToInstall = if ($Pack -eq "all") {
    $AllPacks
} else {
    @(Resolve-PackName $Pack)
}

# --- Resolve target ---
$Target = (Resolve-Path $Target -ErrorAction Stop).Path
$TargetOpencode = Join-Path $Target ".opencode"

# --- Download & extract tarball ---
$tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "skill_builder_$(Get-Random)"
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

try {
    $tarballUrl = "https://github.com/$Repo/archive/refs/heads/$Branch.zip"
    $zipPath = Join-Path $tmpDir "repo.zip"

    Write-Host "Downloading $Repo@$Branch..." -ForegroundColor Cyan
    $webParams = @{ Uri = $tarballUrl; OutFile = $zipPath }
    if ($GitHubToken) {
        $webParams.Headers = @{ Authorization = "token $GitHubToken" }
    }
    Invoke-WebRequest @webParams -UseBasicParsing

    Write-Host "Extracting..."
    Expand-Archive -Path $zipPath -DestinationPath $tmpDir -Force

    # GitHub zips extract into <repo>-<branch>/
    $extractDir = Get-ChildItem -Path $tmpDir -Directory | Where-Object { $_.Name -ne "repo" } | Select-Object -First 1
    if (-not $extractDir) {
        Write-Error "Failed to extract archive"
        exit 1
    }

    $packsDir = Join-Path $extractDir.FullName "packs"

    # --- Install ---
    $installed = 0
    $skipped = 0

    foreach ($packName in $packsToInstall) {
        $packOpencode = Join-Path (Join-Path $packsDir $packName) ".opencode"
        if (-not (Test-Path $packOpencode)) {
            Write-Warning "Pack '$packName' has no .opencode/ directory. Skipping."
            continue
        }

        Write-Host "`nInstalling pack: $packName" -ForegroundColor Green

        $packRoot = Join-Path $packsDir $packName

        # --- Copy root-level AGENTS.md if present ---
        $agentsMd = Join-Path $packRoot "AGENTS.md"
        if (Test-Path $agentsMd) {
            $dstAgents = Join-Path $Target "AGENTS.md"
            if ((Test-Path $dstAgents) -and -not $Force) {
                Write-Warning "  SKIP AGENTS.md (exists, use -Force to overwrite)"
                $skipped++
            } else {
                Copy-Item -Path $agentsMd -Destination $dstAgents -Force
                Write-Host "  + AGENTS.md" -ForegroundColor DarkGreen
                $installed++
            }
        }

        # --- Notify about opencode.example.json if present ---
        $ocExample = Join-Path $packRoot "opencode.example.json"
        if (Test-Path $ocExample) {
            Write-Host "  INFO: Pack includes opencode.example.json — merge into your opencode.json manually if needed." -ForegroundColor Yellow
        }

        foreach ($subdir in @("skills", "commands", "agents")) {
            $srcDir = Join-Path $packOpencode $subdir
            if (-not (Test-Path $srcDir)) { continue }

            $dstDir = Join-Path $TargetOpencode $subdir
            if (-not (Test-Path $dstDir)) {
                New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
            }

            foreach ($item in (Get-ChildItem -Path $srcDir -Directory)) {
                $dstItem = Join-Path $dstDir $item.Name
                if ((Test-Path $dstItem) -and -not $Force) {
                    Write-Warning "  SKIP $subdir/$($item.Name) (exists, use -Force to overwrite)"
                    $skipped++
                    continue
                }
                if (Test-Path $dstItem) {
                    Remove-Item -Path $dstItem -Recurse -Force
                }
                Copy-Item -Path $item.FullName -Destination $dstItem -Recurse
                Write-Host "  + $subdir/$($item.Name)" -ForegroundColor DarkGreen
                $installed++
            }
        }
    }

    Write-Host "`nDone: $installed installed, $skipped skipped." -ForegroundColor Cyan

} finally {
    Remove-Item -Path $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
}
