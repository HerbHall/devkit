# setup/lib/ui.ps1 -- Shared console output library
# Provides: Write-Section, Write-Step, Write-OK, Write-Warn, Write-Fail,
#           Write-VerifyTable, Read-Required, Read-Confirm, Read-Menu,
#           Invoke-ManualChecklist
# Used by all setup scripts for consistent output formatting.

#Requires -Version 7.0

# ---------------------------------------------------------------------------
# ANSI escape sequences -- fall back to plain text when terminal lacks support
# ---------------------------------------------------------------------------

$script:UseColor = $Host.UI.SupportsVirtualTerminal -or $null -ne $PSStyle

if ($script:UseColor) {
    $script:Esc       = [char]0x1B
    $script:Bold      = "${script:Esc}[1m"
    $script:Reset     = "${script:Esc}[0m"
    $script:Green     = "${script:Esc}[32m"
    $script:Yellow    = "${script:Esc}[33m"
    $script:Red       = "${script:Esc}[31m"
    $script:Dim       = "${script:Esc}[2m"
} else {
    $script:Bold      = ''
    $script:Reset     = ''
    $script:Green     = ''
    $script:Yellow    = ''
    $script:Red       = ''
    $script:Dim       = ''
}

# Unicode glyphs (PowerShell 7 handles these fine on Windows Terminal / ConEmu)
$script:CheckMark = [char]0x2714  # heavy check mark
$script:CrossMark = [char]0x2718  # heavy ballot X
$script:WarnMark  = [char]0x26A0  # warning sign

# ============================= Output Functions =============================

function Write-Section {
    <#
    .SYNOPSIS
        Prints a bold phase/section header with a separator line.
    .EXAMPLE
        Write-Section "Phase 2: Core Tool Installs"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Title
    )

    $separator = '-' * [Math]::Min($Title.Length + 4, 72)
    Write-Host ''
    Write-Host "${script:Bold}${Title}${script:Reset}"
    Write-Host "${script:Dim}${separator}${script:Reset}"
}

function Write-Step {
    <#
    .SYNOPSIS
        Prints an indented step description (no color).
    .EXAMPLE
        Write-Step "Installing Git..."
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Message
    )

    Write-Host "  $Message"
}

function Write-OK {
    <#
    .SYNOPSIS
        Prints a green checkmark-prefixed success message.
    .EXAMPLE
        Write-OK "Git 2.47.1 installed"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Message
    )

    Write-Host "  ${script:Green}${script:CheckMark}${script:Reset} $Message"
}

function Write-Warn {
    <#
    .SYNOPSIS
        Prints a yellow warning-prefixed message.
    .EXAMPLE
        Write-Warn "Docker Desktop requires manual config"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Message
    )

    Write-Host "  ${script:Yellow}${script:WarnMark}${script:Reset} $Message"
}

function Write-Fail {
    <#
    .SYNOPSIS
        Prints a red X-prefixed failure message.
    .EXAMPLE
        Write-Fail "Hyper-V not enabled"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Message
    )

    Write-Host "  ${script:Red}${script:CrossMark}${script:Reset} $Message"
}

# ============================ Verify Table ==================================

function Write-VerifyTable {
    <#
    .SYNOPSIS
        Prints an aligned verification results table.
    .DESCRIPTION
        Accepts an array of objects with Name, Status, and Version properties.
        Status values are colored: OK = green, FAIL = red, WARN = yellow.
    .EXAMPLE
        $rows = @(
            [PSCustomObject]@{ Name = 'Git';    Status = 'OK';   Version = '2.47.1' }
            [PSCustomObject]@{ Name = 'Docker'; Status = 'WARN'; Version = '27.4.0' }
            [PSCustomObject]@{ Name = 'Node';   Status = 'FAIL'; Version = '-' }
        )
        Write-VerifyTable $rows
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [PSCustomObject[]]$Items
    )

    if ($Items.Count -eq 0) { return }

    # Calculate column widths
    $nameWidth    = ($Items | ForEach-Object { $_.Name.Length }    | Measure-Object -Maximum).Maximum
    $statusWidth  = ($Items | ForEach-Object { $_.Status.Length }  | Measure-Object -Maximum).Maximum
    $versionWidth = ($Items | ForEach-Object { $_.Version.Length } | Measure-Object -Maximum).Maximum

    # Enforce minimums for readability
    $nameWidth    = [Math]::Max($nameWidth, 4)    # "Name"
    $statusWidth  = [Math]::Max($statusWidth, 6)  # "Status"
    $versionWidth = [Math]::Max($versionWidth, 7) # "Version"

    # Header
    $header = '  {0}  {1}  {2}' -f `
        'Name'.PadRight($nameWidth),
        'Status'.PadRight($statusWidth),
        'Version'.PadRight($versionWidth)
    Write-Host ''
    Write-Host "${script:Bold}${header}${script:Reset}"
    Write-Host "  $('-' * $nameWidth)  $('-' * $statusWidth)  $('-' * $versionWidth)"

    # Rows
    foreach ($item in $Items) {
        $coloredStatus = switch ($item.Status.ToUpper()) {
            'OK'   { "${script:Green}$($item.Status.PadRight($statusWidth))${script:Reset}" }
            'FAIL' { "${script:Red}$($item.Status.PadRight($statusWidth))${script:Reset}" }
            'WARN' { "${script:Yellow}$($item.Status.PadRight($statusWidth))${script:Reset}" }
            default { $item.Status.PadRight($statusWidth) }
        }

        $row = '  {0}  {1}  {2}' -f `
            $item.Name.PadRight($nameWidth),
            $coloredStatus,
            $item.Version.PadRight($versionWidth)
        Write-Host $row
    }
    Write-Host ''
}

# =========================== Interactive Prompts ============================

function Read-Required {
    <#
    .SYNOPSIS
        Prompts for input and loops until a non-empty value is provided.
    .EXAMPLE
        $name = Read-Required "Enter your full name for git config:"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Prompt
    )

    while ($true) {
        Write-Host ''
        $value = Read-Host -Prompt $Prompt
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return $value.Trim()
        }
        Write-Host "  ${script:Yellow}Input required. Please try again.${script:Reset}"
    }
}

function Read-Confirm {
    <#
    .SYNOPSIS
        Asks a yes/no question. Returns $true for yes, $false otherwise.
        Default is no (pressing Enter without input returns $false).
    .EXAMPLE
        if (Read-Confirm "Install 14 packages? (y/N)") { Install-All }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Prompt
    )

    Write-Host ''
    $value = Read-Host -Prompt $Prompt
    return ($value -match '^[Yy]')
}

function Read-Menu {
    <#
    .SYNOPSIS
        Displays a numbered menu and returns the selected string.
        Re-prompts on invalid input.
    .EXAMPLE
        $choice = Read-Menu "Select option:" @("Bootstrap machine", "Add stack", "New project", "Exit")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Prompt,

        [Parameter(Mandatory, Position = 1)]
        [string[]]$Options
    )

    Write-Host ''
    Write-Host "${script:Bold}${Prompt}${script:Reset}"
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "  ${script:Dim}$($i + 1).${script:Reset} $($Options[$i])"
    }

    while ($true) {
        $input = Read-Host -Prompt "  Choice [1-$($Options.Count)]"
        $num = $null
        if ([int]::TryParse($input, [ref]$num) -and $num -ge 1 -and $num -le $Options.Count) {
            return $Options[$num - 1]
        }
        Write-Host "  ${script:Yellow}Invalid selection. Enter a number between 1 and $($Options.Count).${script:Reset}"
    }
}

# ============================ Manual Checklist ==============================

function Invoke-ManualChecklist {
    <#
    .SYNOPSIS
        Walks through a list of manual checklist items, verifying each one.
    .DESCRIPTION
        Each item is a PSCustomObject with these properties:
          - Id           Identifier (e.g., "MC-01")
          - Label        Short description
          - Why          Reason this step matters
          - Instructions Step-by-step instructions for the user
          - CheckFn      ScriptBlock that returns $true when the step is complete

        For each item whose CheckFn returns $false:
          1. Shows the label, why, and instructions.
          2. Waits for the user to press Enter after completing the step.
          3. Re-runs CheckFn to verify.
          4. Reports pass/fail and moves to the next item.

        Returns a PSCustomObject summary with Passed, Failed, and Skipped counts,
        plus a Details array of per-item results.
    .EXAMPLE
        $items = @(
            [PSCustomObject]@{
                Id           = 'MC-01'
                Label        = 'Enable Hyper-V'
                Why          = 'Required for Docker and WSL2'
                Instructions = 'Open Settings > Apps > Optional Features > More Windows Features, check Hyper-V, reboot.'
                CheckFn      = { (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V).State -eq 'Enabled' }
            }
        )
        $summary = Invoke-ManualChecklist $items
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [PSCustomObject[]]$Items
    )

    $details = [System.Collections.Generic.List[PSCustomObject]]::new()
    $passed  = 0
    $failed  = 0
    $skipped = 0

    foreach ($item in $Items) {
        Write-Host ''
        Write-Host "  ${script:Bold}[$($item.Id)] $($item.Label)${script:Reset}"

        # Check if already satisfied
        $alreadyOk = $false
        try {
            $alreadyOk = & $item.CheckFn
        } catch {
            $alreadyOk = $false
        }

        if ($alreadyOk) {
            Write-OK "$($item.Label) -- already done"
            $passed++
            $details.Add([PSCustomObject]@{
                Id     = $item.Id
                Label  = $item.Label
                Result = 'Passed'
                Note   = 'Already satisfied'
            })
            continue
        }

        # Show instructions
        Write-Host "  ${script:Dim}Why:${script:Reset} $($item.Why)"
        Write-Host ''
        foreach ($line in ($item.Instructions -split "`n")) {
            Write-Host "    $line"
        }
        Write-Host ''
        Read-Host -Prompt "  Press Enter after completing this step"

        # Verify
        $verified = $false
        try {
            $verified = & $item.CheckFn
        } catch {
            $verified = $false
        }

        if ($verified) {
            Write-OK "$($item.Label) -- verified"
            $passed++
            $details.Add([PSCustomObject]@{
                Id     = $item.Id
                Label  = $item.Label
                Result = 'Passed'
                Note   = 'Verified after manual step'
            })
        } else {
            Write-Fail "$($item.Label) -- could not verify"
            $failed++
            $details.Add([PSCustomObject]@{
                Id     = $item.Id
                Label  = $item.Label
                Result = 'Failed'
                Note   = 'CheckFn returned false after user action'
            })
        }
    }

    # Summary
    Write-Host ''
    Write-Host "${script:Bold}Checklist Summary${script:Reset}"
    Write-Host "  Passed: ${script:Green}${passed}${script:Reset}  Failed: ${script:Red}${failed}${script:Reset}  Skipped: ${script:Dim}${skipped}${script:Reset}"

    return [PSCustomObject]@{
        Passed  = $passed
        Failed  = $failed
        Skipped = $skipped
        Details = $details.ToArray()
    }
}
