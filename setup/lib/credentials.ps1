# setup/lib/credentials.ps1 -- Windows Credential Manager integration
#
# Provides: Set-DevkitCredential, Get-DevkitCredential, Test-DevkitCredential,
#           Remove-DevkitCredential, Invoke-CredentialCollection
# Stores API tokens and secrets in Windows Credential Manager via cmdkey.
# Retrieves credentials via P/Invoke (advapi32.dll CredReadW).

#Requires -Version 7.0

Set-StrictMode -Version Latest

# ---------------------------------------------------------------------------
# P/Invoke type for reading Generic credentials from Windows Credential Manager
# ---------------------------------------------------------------------------

if (-not ([System.Management.Automation.PSTypeName]'DevkitCredManager').Type) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public class DevkitCredManager {
    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern bool CredReadW(string target, int type, int flags, out IntPtr credential);

    [DllImport("advapi32.dll")]
    public static extern void CredFree(IntPtr credential);

    [StructLayout(LayoutKind.Sequential)]
    public struct CREDENTIAL {
        public int Flags;
        public int Type;
        public string TargetName;
        public string Comment;
        public long LastWritten;
        public int CredentialBlobSize;
        public IntPtr CredentialBlob;
        public int Persist;
        public int AttributeCount;
        public IntPtr Attributes;
        public string TargetAlias;
        public string UserName;
    }

    public static string ReadGenericCredential(string target) {
        IntPtr credPtr;
        // Type 1 = CRED_TYPE_GENERIC
        if (!CredReadW(target, 1, 0, out credPtr)) return null;
        try {
            var cred = Marshal.PtrToStructure<CREDENTIAL>(credPtr);
            if (cred.CredentialBlobSize > 0 && cred.CredentialBlob != IntPtr.Zero) {
                return Marshal.PtrToStringUni(cred.CredentialBlob, cred.CredentialBlobSize / 2);
            }
            return null;
        } finally {
            CredFree(credPtr);
        }
    }
}
'@
}

# ---------------------------------------------------------------------------
# Helper: Convert SecureString to plaintext
# ---------------------------------------------------------------------------

function ConvertFrom-SecureStringPlain {
    <#
    .SYNOPSIS
        Converts a SecureString to a plaintext string.
    .DESCRIPTION
        Uses .NET marshalling to extract the plaintext value from a
        SecureString. The unmanaged memory is freed immediately after
        copying.
    .PARAMETER Secure
        The SecureString to convert.
    .OUTPUTS
        System.String
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Security.SecureString]$Secure
    )

    $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
    try {
        return [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    }
    finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
}

# ---------------------------------------------------------------------------
# Set-DevkitCredential
# ---------------------------------------------------------------------------

function Set-DevkitCredential {
    <#
    .SYNOPSIS
        Stores a credential in Windows Credential Manager.
    .DESCRIPTION
        Uses cmdkey to store a Generic credential. The credential name
        should be prefixed with "devkit/" by convention.
    .PARAMETER Name
        Target name for the credential (e.g. "devkit/github-pat").
    .PARAMETER Value
        The secret value to store.
    .OUTPUTS
        Hashtable with Success key (bool).
    .EXAMPLE
        Set-DevkitCredential -Name "devkit/github-pat" -Value "ghp_abc123"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Value
    )

    try {
        $output = & cmdkey /generic:$Name /user:devkit /pass:$Value 2>&1
        if ($LASTEXITCODE -eq 0) {
            return @{ Success = $true }
        }
        if (Get-Command Write-Warn -ErrorAction SilentlyContinue) {
            Write-Warn "cmdkey failed for '$Name': $output"
        }
        return @{ Success = $false }
    }
    catch {
        if (Get-Command Write-Fail -ErrorAction SilentlyContinue) {
            Write-Fail "Exception storing credential '$Name': $_"
        }
        return @{ Success = $false }
    }
}

# ---------------------------------------------------------------------------
# Get-DevkitCredential
# ---------------------------------------------------------------------------

function Get-DevkitCredential {
    <#
    .SYNOPSIS
        Retrieves a credential value from Windows Credential Manager.
    .DESCRIPTION
        Uses P/Invoke (advapi32.dll CredReadW) to read a Generic
        credential stored by cmdkey or other tools.
    .PARAMETER Name
        Target name for the credential (e.g. "devkit/github-pat").
    .OUTPUTS
        The plaintext credential string, or $null if not found.
    .EXAMPLE
        $pat = Get-DevkitCredential -Name "devkit/github-pat"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    try {
        $value = [DevkitCredManager]::ReadGenericCredential($Name)
        return $value
    }
    catch {
        if (Get-Command Write-Fail -ErrorAction SilentlyContinue) {
            Write-Fail "Exception reading credential '$Name': $_"
        }
        return $null
    }
}

# ---------------------------------------------------------------------------
# Test-DevkitCredential
# ---------------------------------------------------------------------------

function Test-DevkitCredential {
    <#
    .SYNOPSIS
        Checks whether a credential exists in Windows Credential Manager.
    .DESCRIPTION
        Runs cmdkey /list and searches for the target name. Does not
        retrieve the credential value.
    .PARAMETER Name
        Target name for the credential (e.g. "devkit/github-pat").
    .OUTPUTS
        $true if the credential exists, $false otherwise.
    .EXAMPLE
        if (Test-DevkitCredential -Name "devkit/github-pat") { ... }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    try {
        $output = & cmdkey /list 2>&1 | Out-String
        return $output -match [regex]::Escape($Name)
    }
    catch {
        return $false
    }
}

# ---------------------------------------------------------------------------
# Remove-DevkitCredential
# ---------------------------------------------------------------------------

function Remove-DevkitCredential {
    <#
    .SYNOPSIS
        Removes a credential from Windows Credential Manager.
    .DESCRIPTION
        Uses cmdkey /delete to remove a stored credential.
    .PARAMETER Name
        Target name for the credential (e.g. "devkit/github-pat").
    .OUTPUTS
        Hashtable with Success key (bool).
    .EXAMPLE
        Remove-DevkitCredential -Name "devkit/github-pat"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    try {
        $output = & cmdkey /delete:$Name 2>&1
        if ($LASTEXITCODE -eq 0) {
            return @{ Success = $true }
        }
        if (Get-Command Write-Warn -ErrorAction SilentlyContinue) {
            Write-Warn "cmdkey delete failed for '$Name': $output"
        }
        return @{ Success = $false }
    }
    catch {
        if (Get-Command Write-Fail -ErrorAction SilentlyContinue) {
            Write-Fail "Exception removing credential '$Name': $_"
        }
        return @{ Success = $false }
    }
}

# ---------------------------------------------------------------------------
# Invoke-CredentialCollection
# ---------------------------------------------------------------------------

function Invoke-CredentialCollection {
    <#
    .SYNOPSIS
        Interactively collects and stores multiple credentials.
    .DESCRIPTION
        Iterates over a list of credential definitions, checks whether
        each is already stored, and prompts the user for any missing
        values. Supports optional credentials, validation functions,
        and re-prompting on validation failure.

        Credential definitions are PSCustomObject (or hashtable) with:
          - Name            : Credential Manager target name
          - Label           : Human-readable label shown to the user
          - Instructions    : How to obtain the credential
          - ValidateFn      : ScriptBlock that receives the value; returns $true/$false
          - ValidationNote  : Message shown when validation fails
          - Optional        : If $true, empty input skips the credential
    .PARAMETER Credentials
        Array of credential definitions.
    .OUTPUTS
        Hashtable with Stored, Skipped, and Failed counts.
    .EXAMPLE
        $creds = @(
            [PSCustomObject]@{
                Name           = "devkit/github-pat"
                Label          = "GitHub Personal Access Token"
                Instructions   = "Create at https://github.com/settings/tokens"
                ValidateFn     = { param($v) $v -match '^gh[ps]_' }
                ValidationNote = "Token should start with ghp_ or ghs_"
                Optional       = $false
            }
        )
        Invoke-CredentialCollection -Credentials $creds
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Credentials
    )

    $stored = 0
    $skipped = 0
    $failed = 0

    foreach ($cred in $Credentials) {
        $name = $cred.Name
        $label = $cred.Label
        $isOptional = if ($null -ne $cred.Optional) { $cred.Optional } else { $false }

        # Check if already stored
        if (Test-DevkitCredential -Name $name) {
            if (Get-Command Write-OK -ErrorAction SilentlyContinue) {
                Write-OK "$label -- already stored"
            }
            else {
                Write-Host "  OK: $label -- already stored"
            }
            $skipped++
            continue
        }

        # Show instructions
        Write-Host ""
        if (Get-Command Write-Info -ErrorAction SilentlyContinue) {
            Write-Info $label
        }
        else {
            Write-Host "  $label"
        }
        if ($cred.Instructions) {
            Write-Host "  $($cred.Instructions)"
        }
        if ($isOptional) {
            Write-Host "  (Optional -- press Enter to skip)"
        }

        $success = $false
        $maxAttempts = 3

        for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
            $secureValue = Read-Host -Prompt "  Enter value" -AsSecureString
            $plainValue = ConvertFrom-SecureStringPlain -Secure $secureValue

            # Optional credential with empty input -- skip
            if ($isOptional -and [string]::IsNullOrEmpty($plainValue)) {
                if (Get-Command Write-Warn -ErrorAction SilentlyContinue) {
                    Write-Warn "$label -- skipped"
                }
                else {
                    Write-Host "  Skipped: $label"
                }
                $skipped++
                $success = $true
                break
            }

            # Empty input on required credential
            if ([string]::IsNullOrEmpty($plainValue)) {
                if (Get-Command Write-Warn -ErrorAction SilentlyContinue) {
                    Write-Warn "Value cannot be empty ($attempt/$maxAttempts)"
                }
                else {
                    Write-Host "  Value cannot be empty ($attempt/$maxAttempts)"
                }
                continue
            }

            # Validate if a validation function is provided
            if ($null -ne $cred.ValidateFn) {
                $isValid = & $cred.ValidateFn $plainValue
                if (-not $isValid) {
                    $note = if ($cred.ValidationNote) { $cred.ValidationNote } else { "Validation failed" }
                    if (Get-Command Write-Warn -ErrorAction SilentlyContinue) {
                        Write-Warn "$note ($attempt/$maxAttempts)"
                    }
                    else {
                        Write-Host "  $note ($attempt/$maxAttempts)"
                    }
                    continue
                }
            }

            # Store the credential
            $result = Set-DevkitCredential -Name $name -Value $plainValue
            if ($result.Success) {
                if (Get-Command Write-OK -ErrorAction SilentlyContinue) {
                    Write-OK "$label -- stored"
                }
                else {
                    Write-Host "  OK: $label -- stored"
                }
                $stored++
                $success = $true
                break
            }
            else {
                if (Get-Command Write-Fail -ErrorAction SilentlyContinue) {
                    Write-Fail "Failed to store $label ($attempt/$maxAttempts)"
                }
                else {
                    Write-Host "  FAIL: Failed to store $label ($attempt/$maxAttempts)"
                }
            }
        }

        if (-not $success) {
            if (Get-Command Write-Fail -ErrorAction SilentlyContinue) {
                Write-Fail "$label -- failed after $maxAttempts attempts"
            }
            else {
                Write-Host "  FAIL: $label -- failed after $maxAttempts attempts"
            }
            $failed++
        }
    }

    return @{
        Stored  = $stored
        Skipped = $skipped
        Failed  = $failed
    }
}
