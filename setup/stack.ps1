#Requires -Version 7.0
# setup/stack.ps1 -- Kit 2: Profile selection and installer
#
# Usage:
#   .\setup\stack.ps1                        # Interactive menu
#   .\setup\stack.ps1 -List                  # Print available profiles and exit
#   .\setup\stack.ps1 -ShowProfile go-cli    # Print profile body and exit
#   .\setup\stack.ps1 -Install go-cli,go-web # Non-interactive install
#   .\setup\stack.ps1 -Install go-cli -Force # Skip confirmation prompt

param(
    [switch]$List,
    [string]$ShowProfile,
    [string]$Install,
    [switch]$Force
)

Set-StrictMode -Version Latest

# ---------------------------------------------------------------------------
# Dot-source dependencies
# install.ps1 already sources checks.ps1 and ui.ps1
# profiles.ps1 also resolves $script:RepoRoot
# ---------------------------------------------------------------------------

. "$PSScriptRoot\lib\install.ps1"
. "$PSScriptRoot\lib\profiles.ps1"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Get-InstalledVSCodeExtensions {
    <#
    .SYNOPSIS
        Returns a HashSet of installed VS Code extension IDs (lower-cased).
        Returns an empty set if 'code' is not on PATH.
    #>
    $result = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    $codeCheck = Test-Tool 'code'
    if (-not $codeCheck.Met) {
        return $result
    }
    try {
        $tmpIn   = [System.IO.Path]::GetTempFileName()
        $tmpFile = [System.IO.Path]::GetTempFileName()
        $tmpErr  = [System.IO.Path]::GetTempFileName()
        $proc = Start-Process -FilePath 'code' `
            -ArgumentList '--list-extensions' `
            -NoNewWindow -PassThru `
            -RedirectStandardInput  $tmpIn `
            -RedirectStandardOutput $tmpFile `
            -RedirectStandardError  $tmpErr
        $proc.WaitForExit(15000) | Out-Null
        if ($proc.ExitCode -eq 0 -and (Test-Path $tmpFile)) {
            foreach ($line in (Get-Content $tmpFile)) {
                if ($line.Trim() -ne '') {
                    $null = $result.Add($line.Trim())
                }
            }
        }
        $tmpIn, $tmpFile, $tmpErr | Remove-Item -Force -ErrorAction SilentlyContinue
    } catch {
        # Non-fatal -- return empty set
    }
    return $result
}

function Show-ProfileList {
    param([hashtable[]]$Profiles)

    Write-Host ''
    Write-Host 'Available profiles:'
    foreach ($p in $Profiles) {
        $reqStr = if ($p.Requires.Count -gt 0) {
            "  [requires: $($p.Requires -join ', ')]"
        } else {
            ''
        }
        $name = $p.Name.PadRight(16)
        Write-Host "  $name $($p.Description)$reqStr"
    }
    Write-Host ''
}

function Show-InstallDiff {
    <#
    .SYNOPSIS
        Prints a "what will be installed" diff for the given profiles.
        Returns a bool: $true if there is anything to install, $false if everything is already present.
    #>
    param(
        [hashtable[]]$Profiles,
        [System.Collections.Generic.HashSet[string]]$InstalledExtensions
    )

    $anyToInstall = $false

    Write-Section 'What will be installed'

    foreach ($profile in $Profiles) {
        Write-Host ''
        Write-Host "  Profile: $($profile.Name)"

        # Winget packages
        if ($profile.WingetPackages.Count -gt 0) {
            Write-Host '    Winget packages:'
            foreach ($pkg in $profile.WingetPackages) {
                $label = $pkg.Id
                if ($pkg.Note) { $label += " -- $($pkg.Note)" }
                if ($pkg.Check) {
                    $check = Test-Tool $pkg.Check
                    if ($check.Met) {
                        Write-Host "      [skip] $label ($($check.Version))"
                    } else {
                        Write-Host "      [install] $label"
                        $anyToInstall = $true
                    }
                } else {
                    Write-Host "      [install] $label"
                    $anyToInstall = $true
                }
            }
        }

        # Manual installs
        if ($profile.ManualInstalls.Count -gt 0) {
            Write-Host '    Manual installs:'
            foreach ($item in $profile.ManualInstalls) {
                $label = $item.Id
                if ($item.Note) { $label += " -- $($item.Note)" }
                if ($item.Check) {
                    $check = Test-Tool $item.Check
                    if ($check.Met) {
                        Write-Host "      [skip] $label ($($check.Version))"
                    } else {
                        Write-Host "      [install] $label"
                        $anyToInstall = $true
                    }
                } else {
                    Write-Host "      [install] $label"
                    $anyToInstall = $true
                }
            }
        }

        # VS Code extensions
        if ($profile.VSCodeExtensions.Count -gt 0) {
            Write-Host '    VS Code extensions:'
            foreach ($ext in $profile.VSCodeExtensions) {
                if ($InstalledExtensions.Contains($ext)) {
                    Write-Host "      [skip] $ext"
                } else {
                    Write-Host "      [install] $ext"
                    $anyToInstall = $true
                }
            }
        }

        # Claude skills
        if ($profile.ClaudeSkills.Count -gt 0) {
            Write-Host '    Claude skills:'
            foreach ($skill in $profile.ClaudeSkills) {
                $skillDest = Join-Path $HOME '.claude' 'skills' $skill 'SKILL.md'
                if (Test-Path $skillDest) {
                    Write-Host "      [skip] $skill"
                } else {
                    Write-Host "      [install] $skill"
                    $anyToInstall = $true
                }
            }
        }
    }

    Write-Host ''
    return $anyToInstall
}

function Install-Profile {
    <#
    .SYNOPSIS
        Installs all components defined in a profile hashtable.
        Returns $true if all installs succeeded, $false if any failed.
    #>
    param(
        [hashtable]$Profile,
        [System.Collections.Generic.HashSet[string]]$InstalledExtensions
    )

    $allOk = $true

    # Winget packages
    if ($Profile.WingetPackages.Count -gt 0) {
        foreach ($pkg in $Profile.WingetPackages) {
            $splat = @{ Id = $pkg.Id }
            if ($pkg.Check) { $splat.Check = $pkg.Check }
            $result = Install-WingetPackage @splat
            if (-not $result.Success) { $allOk = $false }
        }
    }

    # Manual installs
    if ($Profile.ManualInstalls.Count -gt 0) {
        foreach ($item in $Profile.ManualInstalls) {
            # Skip if already present
            if ($item.Check) {
                $check = Test-Tool $item.Check
                if ($check.Met) {
                    Write-OK "$($item.Id) already installed ($($check.Version))"
                    continue
                }
            }
            $splat = @{
                Label   = $item.Id
                Command = $item.Install
            }
            if ($item.Check) { $splat.Check = $item.Check }
            if ($item.Note)  { $splat.Note  = $item.Note }
            $result = Invoke-ManualInstall @splat
            if (-not $result.Success) { $allOk = $false }
        }
    }

    # VS Code extensions
    if ($Profile.VSCodeExtensions.Count -gt 0) {
        foreach ($ext in $Profile.VSCodeExtensions) {
            if ($InstalledExtensions.Contains($ext)) {
                Write-OK "VS Code extension $ext already installed"
                continue
            }
            $result = Install-VSCodeExtension -Id $ext
            if ($result.Success) {
                $null = $InstalledExtensions.Add($ext)
            } else {
                $allOk = $false
            }
        }
    }

    # Claude skills
    if ($Profile.ClaudeSkills.Count -gt 0) {
        foreach ($skill in $Profile.ClaudeSkills) {
            $skillSrc  = Join-Path $script:RepoRoot 'claude' 'skills' $skill
            $skillDest = Join-Path $HOME '.claude' 'skills' $skill

            if (-not (Test-Path $skillSrc)) {
                Write-Warn "Claude skill '$skill' not found at $skillSrc -- skipping"
                continue
            }

            try {
                $null = New-Item -ItemType Directory -Path (Split-Path $skillDest -Parent) -Force -ErrorAction SilentlyContinue
                Copy-Item -Path $skillSrc -Destination $skillDest -Recurse -Force
                Write-OK "Claude skill $skill installed"
            } catch {
                Write-Fail "Claude skill $skill -- copy failed: $_"
                $allOk = $false
            }
        }
    }

    return $allOk
}

# ---------------------------------------------------------------------------
# -List mode
# ---------------------------------------------------------------------------

if ($List) {
    $allProfiles = Get-AllProfiles
    if ($allProfiles.Count -eq 0) {
        Write-Host 'No profiles found.'
        exit 0
    }
    Show-ProfileList -Profiles $allProfiles
    exit 0
}

# ---------------------------------------------------------------------------
# -ShowProfile mode
# ---------------------------------------------------------------------------

if ($ShowProfile) {
    $profile = Get-Profile -Name $ShowProfile
    if ($null -eq $profile) {
        Write-Host "Profile '$ShowProfile' not found."
        exit 1
    }
    $body = $profile.Body.Trim()
    if ($body) {
        Write-Host $body
    } else {
        Write-Host "(No body content found for profile '$ShowProfile'.)"
    }
    exit 0
}

# ---------------------------------------------------------------------------
# Resolve selected profile names
# (interactive menu or -Install flag)
# ---------------------------------------------------------------------------

$allProfiles = Get-AllProfiles
if ($allProfiles.Count -eq 0) {
    Write-Warn 'No profiles found in profiles/ directory.'
    exit 1
}

if ($Install) {
    # Non-interactive: parse comma-separated names
    $selectedNames = @($Install -split '\s*,\s*' | Where-Object { $_ -ne '' })
} else {
    # Interactive: display numbered list and prompt for selection
    Write-Section 'Kit 2: Add Stack Profile'
    Write-Host ''
    for ($i = 0; $i -lt $allProfiles.Count; $i++) {
        $p      = $allProfiles[$i]
        $reqStr = if ($p.Requires.Count -gt 0) { "  [requires: $($p.Requires -join ', ')]" } else { '' }
        Write-Host "  $($i + 1). $($p.Name.PadRight(16)) $($p.Description)$reqStr"
    }
    Write-Host ''

    $raw = Read-Host 'Select profile(s) by number (e.g., 1 or 1,2)'
    $nums = @($raw -split '\s*,\s*' | Where-Object { $_ -match '^\d+$' })

    if ($nums.Count -eq 0) {
        Write-Warn 'No valid selection. Exiting.'
        exit 1
    }

    $selectedNames = [System.Collections.Generic.List[string]]::new()
    foreach ($numStr in $nums) {
        $idx = [int]$numStr - 1
        if ($idx -lt 0 -or $idx -ge $allProfiles.Count) {
            Write-Warn "Invalid selection: $numStr (valid range: 1-$($allProfiles.Count))"
            exit 1
        }
        $selectedNames.Add($allProfiles[$idx].Name)
    }
    $selectedNames = @($selectedNames)
}

# ---------------------------------------------------------------------------
# Resolve dependencies
# ---------------------------------------------------------------------------

try {
    $installOrder = Resolve-ProfileDeps -Names $selectedNames
} catch {
    Write-Fail "Dependency resolution failed: $_"
    exit 1
}

# Report any auto-added dependencies
$addedDeps = @($installOrder | Where-Object { $selectedNames -notcontains $_ })
if ($addedDeps.Count -gt 0) {
    Write-Host ''
    Write-Host "  Auto-added dependencies: $($addedDeps -join ', ')"
}

# Load the ordered profile objects
$profilesToInstall = [System.Collections.Generic.List[hashtable]]::new()
foreach ($name in $installOrder) {
    $p = Get-Profile -Name $name
    if ($null -eq $p) {
        Write-Fail "Could not load profile '$name'."
        exit 1
    }
    $profilesToInstall.Add($p)
}

# ---------------------------------------------------------------------------
# Pre-install diff
# ---------------------------------------------------------------------------

$installedExtensions = Get-InstalledVSCodeExtensions
$anyToInstall = Show-InstallDiff -Profiles @($profilesToInstall) -InstalledExtensions $installedExtensions

if (-not $anyToInstall) {
    Write-OK 'All tools in selected profiles are already installed.'
    exit 0
}

# ---------------------------------------------------------------------------
# Confirmation
# ---------------------------------------------------------------------------

if (-not $Force) {
    $confirmed = Read-Confirm "Proceed with install? [y/N]"
    if (-not $confirmed) {
        Write-Host '  Cancelled.'
        exit 1
    }
}

# ---------------------------------------------------------------------------
# Install each profile in dependency order
# ---------------------------------------------------------------------------

$totalFailed = 0

foreach ($profile in @($profilesToInstall)) {
    Write-Section "Installing $($profile.Name)..."

    $ok = Install-Profile -Profile $profile -InstalledExtensions $installedExtensions
    if (-not $ok) {
        $totalFailed++
        Write-Warn "$($profile.Name) completed with one or more failures."
    }
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

$count = $profilesToInstall.Count
Write-Section 'Stack install complete'
if ($totalFailed -eq 0) {
    Write-OK "$count profile(s) installed successfully: $($installOrder -join ', ')"
    exit 0
} else {
    Write-Warn "$count profile(s) processed, $totalFailed had failures. Review output above."
    exit 2
}
