<#
.SYNOPSIS
    Install OpenCode skill packs into a target project.

.DESCRIPTION
    Copies .opencode/skills/, .opencode/commands/, and .opencode/agents/
    from one or more skill packs into the target project's .opencode/ directory.

.PARAMETER Pack
    Pack name or alias. Use 'all' to install every pack.
    Aliases: course, testdocs
    Full names also accepted: opencode-course-skills-pack, opencode-skill-pack-testcases-usage-docs

.PARAMETER Target
    Path to the target project. Defaults to current directory.

.PARAMETER Force
    Overwrite existing files without prompting.

.PARAMETER List
    List available packs and exit.

.EXAMPLE
    .\install.ps1 -Pack course -Target C:\my-project
    .\install.ps1 -Pack all
    .\install.ps1 -List
#>
[CmdletBinding()]
param(
    [string]$Pack,
    [string]$Target = ".",
    [switch]$Force,
    [switch]$List
)

$ErrorActionPreference = "Stop"

# Resolve script root (works whether run directly or piped)
$ScriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { $PWD.Path }
$PacksDir = Join-Path $ScriptRoot "packs"

# Pack alias registry
$Aliases = @{
    "course"   = "opencode-course-skills-pack"
    "testdocs" = "opencode-skill-pack-testcases-usage-docs"
}

function Get-PackFullName([string]$name) {
    if ($Aliases.ContainsKey($name)) { return $Aliases[$name] }
    if (Test-Path (Join-Path $PacksDir $name)) { return $name }
    Write-Error "Unknown pack: '$name'. Use -List to see available packs."
    exit 1
}

function Get-AllPacks {
    Get-ChildItem -Path $PacksDir -Directory | ForEach-Object { $_.Name }
}

function Show-PackList {
    Write-Host "`nAvailable packs:" -ForegroundColor Cyan
    Write-Host ("-" * 60)
    foreach ($dir in (Get-AllPacks)) {
        $alias = ($Aliases.GetEnumerator() | Where-Object { $_.Value -eq $dir } | Select-Object -First 1).Key
        $manifest = Join-Path (Join-Path $PacksDir $dir) "pack-manifest.json"
        $info = ""
        if (Test-Path $manifest) {
            $m = Get-Content $manifest -Raw | ConvertFrom-Json
            $info = "  skills=$($m.skill_count)"
            if ($m.PSObject.Properties['command_count']) { $info += " cmds=$($m.command_count)" }
            if ($m.PSObject.Properties['agent_count'])   { $info += " agents=$($m.agent_count)" }
        }
        $aliasLabel = if ($alias) { " (alias: $alias)" } else { "" }
        Write-Host "  $dir$aliasLabel$info"
    }
    Write-Host ""
}

# --- List mode ---
if ($List) {
    Show-PackList
    exit 0
}

if (-not $Pack) {
    Write-Error "Missing -Pack parameter. Use -List to see available packs, or -Pack all."
    exit 1
}

# --- Resolve target ---
$Target = Resolve-Path $Target -ErrorAction Stop
$TargetOpencode = Join-Path $Target ".opencode"

# --- Resolve packs to install ---
$packsToInstall = if ($Pack -eq "all") {
    Get-AllPacks
} else {
    @(Get-PackFullName $Pack)
}

# --- Install ---
$installed = 0
$skipped = 0

foreach ($packName in $packsToInstall) {
    $packOpencode = Join-Path (Join-Path $PacksDir $packName) ".opencode"
    if (-not (Test-Path $packOpencode)) {
        Write-Warning "Pack '$packName' has no .opencode/ directory. Skipping."
        continue
    }

    Write-Host "`nInstalling pack: $packName" -ForegroundColor Green

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
