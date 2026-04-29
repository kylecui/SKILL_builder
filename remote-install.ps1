<#
.SYNOPSIS
    Remote installer for OpenCode skill packs from GitHub. No clone needed.

.DESCRIPTION
    Downloads the repo tarball, extracts the requested pack, and copies
    skills, commands, agents into the target project.
    Supports OpenCode and Antigravity platforms.

.EXAMPLE
    # One-liner:
    & ([scriptblock]::Create((irm https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.ps1))) -Pack course -Target .
    & ([scriptblock]::Create((irm https://raw.githubusercontent.com/kylecui/SKILL_builder/master/remote-install.ps1))) -Pack all -Platform antigravity
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Pack,
    [string]$Target = ".",
    [ValidateSet("opencode", "antigravity", "all")]
    [string]$Platform = "opencode",
    [switch]$Force,
    [switch]$List,
    [string]$Repo = "kylecui/SKILL_builder",
    [string]$Branch = "master",
    [string]$GitHubToken
)

$ErrorActionPreference = "Stop"

# --- Platform path configuration ---

function Get-PlatformConfig([string]$platformName) {
    switch ($platformName) {
        "opencode" {
            return @{
                SkillsDir   = ".opencode/skills"
                AgentsDir   = ".opencode/agents"
                CommandsDir = ".opencode/commands"
                RegistryDir = ".opencode"
                MergeJson   = $true
                GeminiMd    = $false
            }
        }
        "antigravity" {
            return @{
                SkillsDir   = ".agents/skills"
                AgentsDir   = ".agents/rules"
                CommandsDir = ".agents/workflows"
                RegistryDir = ".agents"
                MergeJson   = $false
                GeminiMd    = $true
            }
        }
    }
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

function Update-InstalledPacks([string]$registryDir, [string]$packName, [string]$manifestFile) {
    $regFile = Join-Path $registryDir "installed-packs.json"
    $entry = @{ installed_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ") }

    if (Test-Path $manifestFile) {
        $m = Get-Content $manifestFile -Raw | ConvertFrom-Json
        if ($m.PSObject.Properties['version'])     { $entry.version = $m.version }
        if ($m.PSObject.Properties['skills'])       { $entry.skills = $m.skills }
        if ($m.PSObject.Properties['description'])  { $entry.description = $m.description }
    }

    if (-not (Test-Path $registryDir)) {
        New-Item -ItemType Directory -Path $registryDir -Force | Out-Null
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

# --- Pack alias registry ---
$Aliases = @{
    "course"   = "opencode-course-skills-pack"
    "testdocs" = "opencode-skill-pack-testcases-usage-docs"
    "deploy"   = "repo-deploy-ops-skill-pack"
    "petfish"  = "petfish-style-skill"
    "ppt"      = "opencode-ppt-skills"
}
$AllPacks = @("opencode-course-skills-pack", "opencode-skill-pack-testcases-usage-docs", "repo-deploy-ops-skill-pack", "petfish-style-skill", "opencode-ppt-skills")

# --- List mode ---
if ($List) {
    Write-Host "`nAvailable packs:" -ForegroundColor Cyan
    Write-Host ("-" * 60)
    Write-Host "  opencode-course-skills-pack (alias: course)"
    Write-Host "  opencode-skill-pack-testcases-usage-docs (alias: testdocs)"
    Write-Host "  repo-deploy-ops-skill-pack (alias: deploy)"
    Write-Host "  petfish-style-skill (alias: petfish)"
    Write-Host "  opencode-ppt-skills (alias: ppt)"
    Write-Host ""
    return
}

# --- Resolve pack names ---
function Resolve-PackName([string]$name) {
    if ($Aliases.ContainsKey($name)) { return $Aliases[$name] }
    if ($AllPacks -contains $name) { return $name }
    Write-Error "Unknown pack: '$name'. Available: course, testdocs, deploy, petfish, ppt, all"
    exit 1
}

$packsToInstall = if ($Pack -eq "all") {
    $AllPacks
} else {
    @(Resolve-PackName $Pack)
}

# --- Resolve target ---
$Target = (Resolve-Path $Target -ErrorAction Stop).Path

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

    # --- Install function for a given platform ---
    function Install-ForPlatform([string]$platformName) {
        $cfg = Get-PlatformConfig $platformName

        Write-Host "`n[$platformName] Installing..." -ForegroundColor Magenta

        $installed = 0
        $skipped = 0

        foreach ($packName in $packsToInstall) {
            $packOpencode = Join-Path (Join-Path $packsDir $packName) ".opencode"
            if (-not (Test-Path $packOpencode)) {
                Write-Warning "Pack '$packName' has no .opencode/ directory. Skipping."
                continue
            }

            Write-Host "`n  Installing pack: $packName" -ForegroundColor Green

            $packRoot = Join-Path $packsDir $packName

            # --- Merge AGENTS.md ---
            $agentsMd = Join-Path $packRoot "AGENTS.md"
            if (Test-Path $agentsMd) {
                $dstAgents = Join-Path $Target "AGENTS.md"
                $result = Merge-AgentsMd $agentsMd $dstAgents $packName -ForceOverwrite:$Force
                switch ($result) {
                    "created"  { Write-Host "    + AGENTS.md (created)" -ForegroundColor DarkGreen; $installed++ }
                    "merged"   { Write-Host "    + AGENTS.md (merged)" -ForegroundColor DarkGreen; $installed++ }
                    "updated"  { Write-Host "    + AGENTS.md (updated)" -ForegroundColor DarkGreen; $installed++ }
                    "exists"   { Write-Warning "    SKIP AGENTS.md (pack section exists, use -Force to update)"; $skipped++ }
                }

                # Antigravity: also create/merge GEMINI.md
                if ($cfg.GeminiMd) {
                    $dstGemini = Join-Path $Target "GEMINI.md"
                    $result = Merge-AgentsMd $agentsMd $dstGemini $packName -ForceOverwrite:$Force
                    switch ($result) {
                        "created"  { Write-Host "    + GEMINI.md (created)" -ForegroundColor DarkGreen; $installed++ }
                        "merged"   { Write-Host "    + GEMINI.md (merged)" -ForegroundColor DarkGreen; $installed++ }
                        "updated"  { Write-Host "    + GEMINI.md (updated)" -ForegroundColor DarkGreen; $installed++ }
                        "exists"   { Write-Warning "    SKIP GEMINI.md (pack section exists, use -Force to update)"; $skipped++ }
                    }
                }
            }

            # --- Merge opencode.json (OpenCode only) ---
            if ($cfg.MergeJson) {
                $ocExample = Join-Path $packRoot "opencode.example.json"
                if (Test-Path $ocExample) {
                    $dstOc = Join-Path $Target "opencode.json"
                    $result = Merge-OpencodeJson $ocExample $dstOc -ForceOverwrite:$Force
                    switch ($result) {
                        "created" { Write-Host "    + opencode.json (created from example)" -ForegroundColor DarkGreen; $installed++ }
                        "merged"  { Write-Host "    + opencode.json (merged)" -ForegroundColor DarkGreen; $installed++ }
                    }
                }
            }

            # --- Update installed-packs registry ---
            $targetRegistry = Join-Path $Target $cfg.RegistryDir
            $manifestFile = Join-Path $packRoot "pack-manifest.json"
            Update-InstalledPacks $targetRegistry $packName $manifestFile
            Write-Host "    + $($cfg.RegistryDir)/installed-packs.json (registry updated)" -ForegroundColor DarkGreen

            # --- Copy skills ---
            $srcSkills = Join-Path $packOpencode "skills"
            if (Test-Path $srcSkills) {
                $targetSkills = Join-Path $Target $cfg.SkillsDir
                if (-not (Test-Path $targetSkills)) {
                    New-Item -ItemType Directory -Path $targetSkills -Force | Out-Null
                }
                foreach ($item in (Get-ChildItem -Path $srcSkills -Directory)) {
                    $dstItem = Join-Path $targetSkills $item.Name
                    if ((Test-Path $dstItem) -and -not $Force) {
                        Write-Warning "    SKIP skills/$($item.Name) (exists, use -Force to overwrite)"
                        $skipped++
                        continue
                    }
                    if (Test-Path $dstItem) { Remove-Item -Path $dstItem -Recurse -Force }
                    Copy-Item -Path $item.FullName -Destination $dstItem -Recurse
                    Write-Host "    + skills/$($item.Name)" -ForegroundColor DarkGreen
                    $installed++
                }
            }

            # --- Copy agents ---
            $srcAgents = Join-Path $packOpencode "agents"
            if (Test-Path $srcAgents) {
                $targetAgents = Join-Path $Target $cfg.AgentsDir
                if (-not (Test-Path $targetAgents)) {
                    New-Item -ItemType Directory -Path $targetAgents -Force | Out-Null
                }
                foreach ($item in (Get-ChildItem -Path $srcAgents -Directory)) {
                    $dstItem = Join-Path $targetAgents $item.Name
                    if ((Test-Path $dstItem) -and -not $Force) {
                        Write-Warning "    SKIP agents/$($item.Name) (exists, use -Force to overwrite)"
                        $skipped++
                        continue
                    }
                    if (Test-Path $dstItem) { Remove-Item -Path $dstItem -Recurse -Force }
                    Copy-Item -Path $item.FullName -Destination $dstItem -Recurse
                    Write-Host "    + agents/$($item.Name)" -ForegroundColor DarkGreen
                    $installed++
                }
            }

            # --- Copy commands ---
            $srcCommands = Join-Path $packOpencode "commands"
            if (Test-Path $srcCommands) {
                $targetCommands = Join-Path $Target $cfg.CommandsDir
                if (-not (Test-Path $targetCommands)) {
                    New-Item -ItemType Directory -Path $targetCommands -Force | Out-Null
                }
                foreach ($item in (Get-ChildItem -Path $srcCommands -Directory)) {
                    $dstItem = Join-Path $targetCommands $item.Name
                    if ((Test-Path $dstItem) -and -not $Force) {
                        Write-Warning "    SKIP commands/$($item.Name) (exists, use -Force to overwrite)"
                        $skipped++
                        continue
                    }
                    if (Test-Path $dstItem) { Remove-Item -Path $dstItem -Recurse -Force }
                    Copy-Item -Path $item.FullName -Destination $dstItem -Recurse
                    Write-Host "    + commands/$($item.Name)" -ForegroundColor DarkGreen
                    $installed++
                }
            }
        }

        Write-Host "`n  [$platformName] Done: $installed installed, $skipped skipped." -ForegroundColor Cyan
    }

    # --- Install for selected platform(s) ---
    $platforms = if ($Platform -eq "all") { @("opencode", "antigravity") } else { @($Platform) }

    foreach ($p in $platforms) {
        Install-ForPlatform $p
    }

} finally {
    Remove-Item -Path $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
}
