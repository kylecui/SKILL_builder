<#
.SYNOPSIS
    Install OpenCode skill packs into a target project.

.DESCRIPTION
    Copies .opencode/skills/, .opencode/commands/, and .opencode/agents/
    from one or more skill packs into the target project's .opencode/ directory.

.PARAMETER Pack
    Pack name or alias. Use 'all' to install every pack.
    Aliases: course, testdocs, deploy, petfish, ppt
    Full names also accepted.

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
    "deploy"   = "repo-deploy-ops-skill-pack"
    "petfish"  = "petfish-style-skill"
    "ppt"      = "opencode-ppt-skills"
}

# --- Merge helpers ---

function Merge-AgentsMd([string]$srcFile, [string]$dstFile, [string]$packName, [switch]$ForceOverwrite) {
    $beginMarker = "<!-- BEGIN pack: $packName -->"
    $endMarker = "<!-- END pack: $packName -->"
    $srcContent = (Get-Content $srcFile -Raw).TrimEnd()
    $wrappedContent = "$beginMarker`n$srcContent`n$endMarker"

    if (-not (Test-Path $dstFile)) {
        Set-Content -Path $dstFile -Value $wrappedContent -NoNewline
        return "created"
    }

    $existing = Get-Content $dstFile -Raw
    if ($existing -match [regex]::Escape($beginMarker)) {
        if (-not $ForceOverwrite) { return "exists" }
        $pattern = "(?s)" + [regex]::Escape($beginMarker) + ".*?" + [regex]::Escape($endMarker)
        $replaced = [regex]::Replace($existing, $pattern, $wrappedContent)
        Set-Content -Path $dstFile -Value $replaced -NoNewline
        return "updated"
    }

    $merged = $existing.TrimEnd() + "`n`n" + $wrappedContent + "`n"
    Set-Content -Path $dstFile -Value $merged -NoNewline
    return "merged"
}

function Merge-OpencodeJson([string]$srcFile, [string]$dstFile, [switch]$ForceOverwrite) {
    if (-not (Test-Path $dstFile)) {
        Copy-Item $srcFile $dstFile
        return "created"
    }

    $src = Get-Content $srcFile -Raw | ConvertFrom-Json
    $dst = Get-Content $dstFile -Raw | ConvertFrom-Json

    # Recursive shallow merge (3 levels deep: permission.skill.X = "allow")
    foreach ($p1 in $src.PSObject.Properties) {
        if (-not $dst.PSObject.Properties[$p1.Name]) {
            $dst | Add-Member -NotePropertyName $p1.Name -NotePropertyValue $p1.Value
        } elseif ($p1.Value -is [PSCustomObject] -and $dst.($p1.Name) -is [PSCustomObject]) {
            foreach ($p2 in $p1.Value.PSObject.Properties) {
                $level2 = $dst.($p1.Name)
                if (-not $level2.PSObject.Properties[$p2.Name]) {
                    $level2 | Add-Member -NotePropertyName $p2.Name -NotePropertyValue $p2.Value
                } elseif ($p2.Value -is [PSCustomObject] -and $level2.($p2.Name) -is [PSCustomObject]) {
                    foreach ($p3 in $p2.Value.PSObject.Properties) {
                        $level3 = $level2.($p2.Name)
                        if (-not $level3.PSObject.Properties[$p3.Name] -or $ForceOverwrite) {
                            if ($level3.PSObject.Properties[$p3.Name]) {
                                $level3.($p3.Name) = $p3.Value
                            } else {
                                $level3 | Add-Member -NotePropertyName $p3.Name -NotePropertyValue $p3.Value
                            }
                        }
                    }
                } elseif ($ForceOverwrite) {
                    $level2.($p2.Name) = $p2.Value
                }
            }
        } elseif ($ForceOverwrite) {
            $dst.($p1.Name) = $p1.Value
        }
    }

    $dst | ConvertTo-Json -Depth 10 | Set-Content $dstFile
    return "merged"
}

function Update-InstalledPacks([string]$targetOpencode, [string]$packName, [string]$manifestFile) {
    $regFile = Join-Path $targetOpencode "installed-packs.json"
    $entry = @{ installed_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ") }

    if (Test-Path $manifestFile) {
        $m = Get-Content $manifestFile -Raw | ConvertFrom-Json
        if ($m.PSObject.Properties['version'])     { $entry.version = $m.version }
        if ($m.PSObject.Properties['skills'])       { $entry.skills = $m.skills }
        if ($m.PSObject.Properties['description'])  { $entry.description = $m.description }
    }

    if (-not (Test-Path $targetOpencode)) {
        New-Item -ItemType Directory -Path $targetOpencode -Force | Out-Null
    }

    if (Test-Path $regFile) {
        $reg = Get-Content $regFile -Raw | ConvertFrom-Json
    } else {
        $reg = [PSCustomObject]@{ packs = [PSCustomObject]@{} }
    }

    $entryObj = [PSCustomObject]$entry
    if ($reg.packs.PSObject.Properties[$packName]) {
        $reg.packs.$packName = $entryObj
    } else {
        $reg.packs | Add-Member -NotePropertyName $packName -NotePropertyValue $entryObj
    }

    $reg | ConvertTo-Json -Depth 10 | Set-Content $regFile
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

    $packRoot = Join-Path $PacksDir $packName

    # --- Merge AGENTS.md ---
    $agentsMd = Join-Path $packRoot "AGENTS.md"
    if (Test-Path $agentsMd) {
        $dstAgents = Join-Path $Target "AGENTS.md"
        $result = Merge-AgentsMd $agentsMd $dstAgents $packName -ForceOverwrite:$Force
        switch ($result) {
            "created"  { Write-Host "  + AGENTS.md (created)" -ForegroundColor DarkGreen; $installed++ }
            "merged"   { Write-Host "  + AGENTS.md (merged)" -ForegroundColor DarkGreen; $installed++ }
            "updated"  { Write-Host "  + AGENTS.md (updated)" -ForegroundColor DarkGreen; $installed++ }
            "exists"   { Write-Warning "  SKIP AGENTS.md (pack section exists, use -Force to update)"; $skipped++ }
        }
    }

    # --- Merge opencode.json from opencode.example.json ---
    $ocExample = Join-Path $packRoot "opencode.example.json"
    if (Test-Path $ocExample) {
        $dstOc = Join-Path $Target "opencode.json"
        $result = Merge-OpencodeJson $ocExample $dstOc -ForceOverwrite:$Force
        switch ($result) {
            "created" { Write-Host "  + opencode.json (created from example)" -ForegroundColor DarkGreen; $installed++ }
            "merged"  { Write-Host "  + opencode.json (merged)" -ForegroundColor DarkGreen; $installed++ }
        }
    }

    # --- Update installed-packs registry ---
    $manifestFile = Join-Path $packRoot "pack-manifest.json"
    Update-InstalledPacks $TargetOpencode $packName $manifestFile
    Write-Host "  + .opencode/installed-packs.json (registry updated)" -ForegroundColor DarkGreen

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
