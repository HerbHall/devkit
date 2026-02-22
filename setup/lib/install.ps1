# setup/lib/install.ps1 -- Winget and manual install wrappers
# Provides: Install-WingetPackage, Install-WingetPackages, Install-VSCodeExtension,
#           Install-VSCodeExtensions, Invoke-ManualInstall, Export-WingetManifest,
#           Export-VSCodeExtensions
# Used by bootstrap.ps1 and stack.ps1 for idempotent tool installation.

#Requires -Version 7.0
Set-StrictMode -Version Latest

# Dot-source dependencies
. "$PSScriptRoot\checks.ps1"
. "$PSScriptRoot\ui.ps1"

function Install-WingetPackage {
    <#
    .SYNOPSIS
        Installs a package via winget if not already present.
    .DESCRIPTION
        Checks whether the tool is already installed using Test-Tool from checks.ps1.
        If installed, reports the current version and returns early. If not, invokes
        winget install with silent flags. Winget output is captured and only shown
        on failure.
    .PARAMETER Id
        The winget package identifier (e.g., "Git.Git").
    .PARAMETER Check
        Optional command used to verify the tool is installed (e.g., "git --version").
        Passed to Test-Tool. If omitted, skips the pre-install check and always
        attempts the winget install.
    .OUTPUTS
        Hashtable with keys: Success (bool), AlreadyInstalled (bool), Version (string or $null).
    .EXAMPLE
        Install-WingetPackage -Id "Git.Git" -Check "git"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Id,

        [Parameter()]
        [string]$Check
    )

    # Pre-install check: if a verification command is provided, see if the tool exists
    if ($Check) {
        $testResult = Test-Tool $Check
        if ($testResult.Met) {
            Write-OK "$Id already installed ($($testResult.Version))"
            return @{
                Success          = $true
                AlreadyInstalled = $true
                Version          = $testResult.Version
            }
        }
    }

    # Verify winget is available
    $wingetCheck = Test-Tool 'winget'
    if (-not $wingetCheck.Met) {
        Write-Fail "$Id -- winget is not available on this system"
        return @{
            Success          = $false
            AlreadyInstalled = $false
            Version          = $null
        }
    }

    # Attempt winget install with progress spinner
    Write-Step "Installing $Id via winget..."
    $stdoutFile = [IO.Path]::GetTempFileName()
    $stderrFile = [IO.Path]::GetTempFileName()
    try {
        $proc = Start-Process -FilePath 'winget' `
            -ArgumentList 'install', '--id', $Id, '--silent', '--accept-source-agreements', '--accept-package-agreements' `
            -NoNewWindow -PassThru `
            -RedirectStandardOutput $stdoutFile `
            -RedirectStandardError $stderrFile

        Wait-ProcessWithSpinner -Process $proc -Label "winget install $Id"

        $output = ''
        if (Test-Path $stdoutFile) { $output += Get-Content $stdoutFile -Raw -ErrorAction SilentlyContinue }
        if (Test-Path $stderrFile) { $output += Get-Content $stderrFile -Raw -ErrorAction SilentlyContinue }
        $exitCode = $proc.ExitCode
    }
    catch {
        Write-Fail "$Id -- winget threw an exception: $_"
        return @{
            Success          = $false
            AlreadyInstalled = $false
            Version          = $null
        }
    }
    finally {
        Remove-Item $stdoutFile, $stderrFile -Force -ErrorAction SilentlyContinue
    }

    # -1978335189 (0x8A150011) = no upgrade available (already installed at latest)
    # -1978335184 (0x8A150016) = already installed
    if ($exitCode -eq -1978335189 -or $exitCode -eq -1978335184) {
        Write-OK "$Id already installed (up to date)"
        return @{
            Success          = $true
            AlreadyInstalled = $true
            Version          = $null
        }
    }

    if ($exitCode -ne 0) {
        Write-Fail "$Id -- winget exited with code $exitCode"
        Write-Warn "Winget output:`n$output"
        return @{
            Success          = $false
            AlreadyInstalled = $false
            Version          = $null
        }
    }

    # Post-install verification
    $version = $null
    if ($Check) {
        $postCheck = Test-Tool $Check
        if ($postCheck.Met) {
            $version = $postCheck.Version
        }
    }

    Write-OK "$Id installed$(if ($version) { " ($version)" })"
    return @{
        Success          = $true
        AlreadyInstalled = $false
        Version          = $version
    }
}

function Install-WingetPackages {
    <#
    .SYNOPSIS
        Installs multiple winget packages in sequence.
    .DESCRIPTION
        Iterates over an array of package definitions, calling Install-WingetPackage
        for each. Tracks installed, skipped (already present), and failed counts.
        Optionally stops on first failure.
    .PARAMETER Packages
        Array of hashtables, each with keys: Id (string, required), Check (string, optional).
    .PARAMETER StopOnFailure
        If $true, stops processing after the first failed install. Default: $false.
    .OUTPUTS
        Hashtable with keys: Installed (int), Skipped (int), Failed (int), Failures (array of strings).
    .EXAMPLE
        $pkgs = @(
            @{ Id = "Git.Git"; Check = "git" },
            @{ Id = "GitHub.cli"; Check = "gh" }
        )
        Install-WingetPackages -Packages $pkgs
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable[]]$Packages,

        [Parameter()]
        [bool]$StopOnFailure = $false
    )

    $installed = 0
    $skipped = 0
    $failed = 0
    $failures = [System.Collections.Generic.List[string]]::new()

    foreach ($pkg in $Packages) {
        $splat = @{ Id = $pkg.Id }
        if ($pkg.ContainsKey('Check') -and $pkg.Check) {
            $splat.Check = $pkg.Check
        }

        $result = Install-WingetPackage @splat

        if ($result.Success -and $result.AlreadyInstalled) {
            $skipped++
        }
        elseif ($result.Success) {
            $installed++
        }
        else {
            $failed++
            $failures.Add($pkg.Id)
            if ($StopOnFailure) {
                Write-Warn "Stopping batch install after failure: $($pkg.Id)"
                break
            }
        }
    }

    return @{
        Installed = $installed
        Skipped   = $skipped
        Failed    = $failed
        Failures  = @($failures)
    }
}

function Install-VSCodeExtension {
    <#
    .SYNOPSIS
        Installs a VS Code extension by ID.
    .DESCRIPTION
        Runs 'code --install-extension' with --force. Handles the case where the
        'code' command is not available on PATH.
    .PARAMETER Id
        The extension identifier (e.g., "golang.go").
    .OUTPUTS
        Hashtable with key: Success (bool).
    .EXAMPLE
        Install-VSCodeExtension -Id "golang.go"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Id
    )

    # Verify VS Code CLI is available
    $codeCheck = Test-Tool 'code'
    if (-not $codeCheck.Met) {
        Write-Fail "VS Code extension $Id -- 'code' command not found on PATH"
        return @{ Success = $false }
    }

    Write-Step "Installing VS Code extension $Id..."
    $stdinFile  = [IO.Path]::GetTempFileName()
    $stdoutFile = [IO.Path]::GetTempFileName()
    $stderrFile = [IO.Path]::GetTempFileName()
    try {
        # Redirect all three streams to fully decouple from VS Code's IPC
        # (without stdin redirect, VS Code opens temp editor tabs)
        $proc = Start-Process -FilePath 'code' `
            -ArgumentList '--install-extension', $Id, '--force' `
            -NoNewWindow -PassThru `
            -RedirectStandardInput  $stdinFile `
            -RedirectStandardOutput $stdoutFile `
            -RedirectStandardError  $stderrFile

        Wait-ProcessWithSpinner -Process $proc -Label "VS Code ext $Id"
        $exitCode = $proc.ExitCode
    }
    catch {
        Write-Fail "VS Code extension $Id -- exception: $_"
        return @{ Success = $false }
    }
    finally {
        $output = ''
        if (Test-Path $stdoutFile) { $output += Get-Content $stdoutFile -Raw -ErrorAction SilentlyContinue }
        if (Test-Path $stderrFile) { $output += Get-Content $stderrFile -Raw -ErrorAction SilentlyContinue }
        $stdinFile, $stdoutFile, $stderrFile | Remove-Item -Force -ErrorAction SilentlyContinue
    }

    if ($exitCode -ne 0) {
        Write-Fail "VS Code extension $Id -- exited with code $exitCode"
        Write-Warn "Output:`n$output"
        return @{ Success = $false }
    }

    Write-OK "VS Code extension $Id installed"
    return @{ Success = $true }
}

function Install-VSCodeExtensions {
    <#
    .SYNOPSIS
        Installs multiple VS Code extensions.
    .DESCRIPTION
        Batch wrapper around Install-VSCodeExtension. Reports installed and failed
        counts with a list of failure IDs.
    .PARAMETER Ids
        Array of extension identifier strings.
    .OUTPUTS
        Hashtable with keys: Installed (int), Failed (int), Failures (array of strings).
    .EXAMPLE
        Install-VSCodeExtensions -Ids @("golang.go", "zxh404.vscode-proto3")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Ids
    )

    $installed = 0
    $failed = 0
    $failures = [System.Collections.Generic.List[string]]::new()

    foreach ($id in $Ids) {
        $result = Install-VSCodeExtension -Id $id
        if ($result.Success) {
            $installed++
        }
        else {
            $failed++
            $failures.Add($id)
        }
    }

    return @{
        Installed = $installed
        Failed    = $failed
        Failures  = @($failures)
    }
}

function Invoke-ManualInstall {
    <#
    .SYNOPSIS
        Auto-executes an install command with error checking and verification.
    .DESCRIPTION
        Runs the install command directly in a child process, captures output,
        and verifies success via the check command. Falls back to displaying
        the command for manual execution only if auto-execution fails.
    .PARAMETER Label
        Human-readable name for the tool being installed.
    .PARAMETER Command
        The command string to execute.
    .PARAMETER Check
        Optional verification command passed to Test-Tool after install.
    .PARAMETER Note
        Optional additional guidance shown on failure.
    .OUTPUTS
        Hashtable with key: Success (bool).
    .EXAMPLE
        Invoke-ManualInstall -Label "golangci-lint" `
            -Command "go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest" `
            -Check "golangci-lint"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Label,

        [Parameter(Mandatory)]
        [string]$Command,

        [Parameter()]
        [string]$Check,

        [Parameter()]
        [string]$Note
    )

    Write-Step "Installing $Label..."

    # Refresh PATH so tools installed earlier in this session are visible
    $machinePath = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
    $userPath    = [Environment]::GetEnvironmentVariable('PATH', 'User')
    $env:PATH    = "$machinePath;$userPath"

    # Execute in a child process to isolate failures and capture output
    $stdoutFile = [IO.Path]::GetTempFileName()
    $stderrFile = [IO.Path]::GetTempFileName()

    try {
        $proc = Start-Process -FilePath 'pwsh' `
            -ArgumentList '-NoProfile', '-Command', $Command `
            -NoNewWindow -PassThru `
            -RedirectStandardOutput $stdoutFile `
            -RedirectStandardError $stderrFile

        Wait-ProcessWithSpinner -Process $proc -Label $Label

        $stderr = if (Test-Path $stderrFile) { (Get-Content $stderrFile -Raw).Trim() } else { '' }

        if ($proc.ExitCode -ne 0) {
            Write-Fail "$Label install failed (exit code $($proc.ExitCode))"
            if ($stderr) { Write-Host "  $stderr" -ForegroundColor Red }
            if ($Note)   { Write-Warn "Note: $Note" }
            return @{ Success = $false }
        }
    }
    catch {
        Write-Fail "$Label install error: $($_.Exception.Message)"
        if ($Note) { Write-Warn "Note: $Note" }
        return @{ Success = $false }
    }
    finally {
        Remove-Item $stdoutFile, $stderrFile -Force -ErrorAction SilentlyContinue
    }

    # Refresh PATH again -- the install may have added new entries
    $machinePath = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
    $userPath    = [Environment]::GetEnvironmentVariable('PATH', 'User')
    $env:PATH    = "$machinePath;$userPath"

    # Verify if a check command was provided
    if ($Check) {
        $testResult = Test-Tool $Check
        if ($testResult.Met) {
            Write-OK "$Label installed ($($testResult.Version))"
            return @{ Success = $true }
        }
        else {
            Write-Warn "$Label installed but not found on PATH -- you may need to restart your terminal"
            return @{ Success = $false }
        }
    }

    Write-OK "$Label installed"
    return @{ Success = $true }
}

function Export-WingetManifest {
    <#
    .SYNOPSIS
        Exports the current winget package list to a file.
    .DESCRIPTION
        Runs 'winget export' with version information to produce a JSON manifest
        that can be used with 'winget import' to reproduce the machine state.
    .PARAMETER Path
        Output file path for the winget manifest.
    .OUTPUTS
        Hashtable with keys: Success (bool), Path (string).
    .EXAMPLE
        Export-WingetManifest -Path "machine/winget.json"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    # Verify winget is available
    $wingetCheck = Test-Tool 'winget'
    if (-not $wingetCheck.Met) {
        Write-Fail "Cannot export winget manifest -- winget not available"
        return @{ Success = $false; Path = $Path }
    }

    Write-Step "Exporting winget manifest to $Path..."

    # Ensure parent directory exists
    $parentDir = Split-Path -Path $Path -Parent
    if ($parentDir -and -not (Test-Path $parentDir)) {
        $null = New-Item -ItemType Directory -Path $parentDir -Force
    }

    $stdoutFile = [IO.Path]::GetTempFileName()
    $stderrFile = [IO.Path]::GetTempFileName()
    try {
        $proc = Start-Process -FilePath 'winget' `
            -ArgumentList 'export', '-o', $Path, '--include-versions' `
            -NoNewWindow -PassThru `
            -RedirectStandardOutput $stdoutFile `
            -RedirectStandardError $stderrFile

        Wait-ProcessWithSpinner -Process $proc -Label "winget export"

        $output = ''
        if (Test-Path $stderrFile) { $output = Get-Content $stderrFile -Raw -ErrorAction SilentlyContinue }
        $exitCode = $proc.ExitCode
    }
    catch {
        Write-Fail "Winget export failed: $_"
        return @{ Success = $false; Path = $Path }
    }
    finally {
        Remove-Item $stdoutFile, $stderrFile -Force -ErrorAction SilentlyContinue
    }

    if ($exitCode -ne 0) {
        Write-Fail "Winget export exited with code $exitCode"
        Write-Warn "Output:`n$output"
        return @{ Success = $false; Path = $Path }
    }

    Write-OK "Winget manifest exported to $Path"
    return @{ Success = $true; Path = $Path }
}

function Export-VSCodeExtensions {
    <#
    .SYNOPSIS
        Exports the list of installed VS Code extensions to a file.
    .DESCRIPTION
        Runs 'code --list-extensions' and writes the output to the specified path.
        The resulting file has one extension ID per line, compatible with
        'code --install-extension' for restoring extensions.
    .PARAMETER Path
        Output file path for the extension list.
    .OUTPUTS
        Hashtable with keys: Success (bool), Path (string).
    .EXAMPLE
        Export-VSCodeExtensions -Path "machine/vscode-extensions.txt"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    # Verify VS Code CLI is available
    $codeCheck = Test-Tool 'code'
    if (-not $codeCheck.Met) {
        Write-Fail "Cannot export VS Code extensions -- 'code' command not found"
        return @{ Success = $false; Path = $Path }
    }

    Write-Step "Exporting VS Code extensions to $Path..."

    # Ensure parent directory exists
    $parentDir = Split-Path -Path $Path -Parent
    if ($parentDir -and -not (Test-Path $parentDir)) {
        $null = New-Item -ItemType Directory -Path $parentDir -Force
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
        $exitCode = $proc.ExitCode
        $tmpIn, $tmpErr | Remove-Item -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-Fail "VS Code extension list failed: $_"
        return @{ Success = $false; Path = $Path }
    }

    if ($exitCode -ne 0) {
        Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
        Write-Fail "VS Code extension list exited with code $exitCode"
        return @{ Success = $false; Path = $Path }
    }

    try {
        Copy-Item -Path $tmpFile -Destination $Path -Force
        Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-Fail "Failed to write extensions to $Path -- $_"
        return @{ Success = $false; Path = $Path }
    }

    Write-OK "VS Code extensions exported to $Path"
    return @{ Success = $true; Path = $Path }
}
