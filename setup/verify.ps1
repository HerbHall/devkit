# setup/verify.ps1 -- Verify DevKit installation and tool availability
#
# Checks core tools, Windows features, credentials, Claude skills,
# and symlink state. Uses the same test functions as bootstrap Phase 6.
#
# Usage:
#   pwsh -File verify.ps1

#Requires -Version 7.0

param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

. (Join-Path $ScriptDir 'lib' 'ui.ps1')
. (Join-Path $ScriptDir 'lib' 'checks.ps1')
. (Join-Path $ScriptDir 'lib' 'credentials.ps1')

# Refresh PATH from registry so recently installed tools are found
$machinePath = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
$userPath    = [Environment]::GetEnvironmentVariable('PATH', 'User')
$env:PATH    = "$machinePath;$userPath"

$total   = 0
$passed  = 0
$failed  = 0
$skipped = 0

# ---------------------------------------------------------------------------
# 1. Core tools
# ---------------------------------------------------------------------------

Write-Section 'Verification: Core Tools'
$tools = @(
    @{ Name = 'git';     Check = 'git' },
    @{ Name = 'gh';      Check = 'gh' },
    @{ Name = 'node';    Check = 'node' },
    @{ Name = 'go';      Check = 'go' },
    @{ Name = 'docker';  Check = 'docker' },
    @{ Name = 'code';    Check = 'code' },
    @{ Name = 'pwsh';    Check = 'pwsh' },
    @{ Name = 'rustup';  Check = 'rustup' },
    @{ Name = 'cmake';   Check = 'cmake' }
)

$toolRows = [System.Collections.Generic.List[PSCustomObject]]::new()
foreach ($tool in $tools) {
    $result = Test-Tool $tool.Check
    $total++
    if ($result.Met) {
        $passed++
        $toolRows.Add([PSCustomObject]@{ Name = $tool.Name; Status = 'OK'; Version = ($result.Version ?? '-') })
    }
    else {
        $failed++
        $toolRows.Add([PSCustomObject]@{ Name = $tool.Name; Status = 'FAIL'; Version = '-' })
    }
}
Write-VerifyTable $toolRows.ToArray()

# ---------------------------------------------------------------------------
# 2. Windows features
# ---------------------------------------------------------------------------

Write-Host ''
Write-Section 'Verification: Windows Features'
$featureRows = [System.Collections.Generic.List[PSCustomObject]]::new()

$hyperv = Test-HyperV
$total++
if ($hyperv.Met) { $passed++ } else { $failed++ }
$featureRows.Add([PSCustomObject]@{
    Name    = 'Hyper-V'
    Status  = if ($hyperv.Met) { 'OK' } else { 'FAIL' }
    Version = if ($hyperv.Met) { 'enabled' } else { 'disabled' }
})

$wsl = Test-WSL2
$total++
if ($wsl.Met) { $passed++ } else { $failed++ }
$featureRows.Add([PSCustomObject]@{
    Name    = 'WSL2'
    Status  = if ($wsl.Met) { 'OK' } else { 'FAIL' }
    Version = if ($wsl.Met -and $wsl.Version) { $wsl.Version } elseif ($wsl.Met) { 'enabled' } else { 'disabled' }
})

$virt = Test-Virtualization
$virtMet = $virt.Met -or $hyperv.Met
$total++
if ($virtMet) { $passed++ } else { $failed++ }
$featureRows.Add([PSCustomObject]@{
    Name    = 'Virtualization'
    Status  = if ($virtMet) { 'OK' } else { 'FAIL' }
    Version = if ($virtMet) { 'enabled' } else { 'disabled' }
})

$devmode = Test-DeveloperMode
$total++
if ($devmode.Met) { $passed++ } else { $failed++ }
$featureRows.Add([PSCustomObject]@{
    Name    = 'Developer Mode'
    Status  = if ($devmode.Met) { 'OK' } else { 'FAIL' }
    Version = if ($devmode.Met) { 'enabled' } else { 'disabled' }
})

Write-VerifyTable $featureRows.ToArray()

# ---------------------------------------------------------------------------
# 3. Credentials
# ---------------------------------------------------------------------------

Write-Host ''
Write-Section 'Verification: Credentials'
$credRows = [System.Collections.Generic.List[PSCustomObject]]::new()
$credChecks = @(
    @{ Name = 'GitHub PAT';    CredName = 'devkit/github-pat';   Optional = $false },
    @{ Name = 'Anthropic Key'; CredName = 'devkit/anthropic-key'; Optional = $false },
    @{ Name = 'Docker Hub';    CredName = 'devkit/docker-hub';    Optional = $true }
)

foreach ($cred in $credChecks) {
    $total++
    $exists = Test-DevkitCredential -Name $cred.CredName
    if ($exists) {
        $passed++
        $credRows.Add([PSCustomObject]@{ Name = $cred.Name; Status = 'OK'; Version = 'stored' })
    }
    elseif ($cred.Optional) {
        $skipped++
        $credRows.Add([PSCustomObject]@{ Name = $cred.Name; Status = 'WARN'; Version = 'skipped' })
    }
    else {
        $failed++
        $credRows.Add([PSCustomObject]@{ Name = $cred.Name; Status = 'FAIL'; Version = 'missing' })
    }
}
Write-VerifyTable $credRows.ToArray()

# ---------------------------------------------------------------------------
# 4. Claude skills
# ---------------------------------------------------------------------------

Write-Host ''
Write-Section 'Verification: Claude Skills'
$skillRows = [System.Collections.Generic.List[PSCustomObject]]::new()
$claudeSkillsDir = Join-Path $HOME '.claude' 'skills'

if (Test-Path $claudeSkillsDir) {
    $installedSkills = Get-ChildItem -Path $claudeSkillsDir -Directory
    foreach ($skill in $installedSkills) {
        $total++
        $skillMd = Join-Path $skill.FullName 'SKILL.md'
        if (Test-Path $skillMd) {
            $passed++
            $skillRows.Add([PSCustomObject]@{ Name = $skill.Name; Status = 'OK'; Version = 'present' })
        }
        else {
            $failed++
            $skillRows.Add([PSCustomObject]@{ Name = $skill.Name; Status = 'FAIL'; Version = 'missing SKILL.md' })
        }
    }
}
else {
    $skillRows.Add([PSCustomObject]@{ Name = '(no skills directory)'; Status = 'FAIL'; Version = '-' })
    $total++
    $failed++
}
Write-VerifyTable $skillRows.ToArray()

# ---------------------------------------------------------------------------
# 5. Symlink state (via sync.ps1 -Verify logic)
# ---------------------------------------------------------------------------

Write-Host ''
Write-Section 'Verification: Symlinks'
$syncScript = Join-Path $ScriptDir 'sync.ps1'
if (Test-Path $syncScript) {
    Write-Step 'Running sync.ps1 -Verify...'
    try {
        & pwsh -NoProfile -File $syncScript -Verify
    }
    catch {
        Write-Fail "Symlink verification failed: $_"
        $failed++
        $total++
    }
}
else {
    Write-Warn 'sync.ps1 not found -- skipping symlink verification'
    $skipped++
    $total++
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

Write-Host ''
$optionalNote = if ($skipped -gt 0) { " ($skipped optional, skipped)" } else { '' }
Write-Section "Verification complete: $passed/$total checks passed${optionalNote}"

if ($failed -gt 0) {
    Write-Host ''
    Write-Warn "$failed check(s) failed. Review the output above for details."
    Write-Host ''
    Write-Step 'To fix:'
    Write-Host '  - Missing tools: run "pwsh -File setup.ps1 -Kit bootstrap"'
    Write-Host '  - Missing credentials: run "pwsh -File setup.ps1 -Kit bootstrap" Phase 5'
    Write-Host '  - Broken symlinks: run "pwsh -File sync.ps1 -Link"'
    Write-Host ''
}
