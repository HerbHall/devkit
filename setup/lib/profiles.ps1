# setup/lib/profiles.ps1 -- Profile format parser
#
# Provides: ConvertFrom-SimpleFrontmatter, Get-ProfileFromFile,
#           Get-AllProfiles, Get-Profile, Resolve-ProfileDeps
# Parses profile markdown files with YAML frontmatter. No external deps.

#Requires -Version 7.0

Set-StrictMode -Version Latest

# ---------------------------------------------------------------------------
# Resolve repo root (used by profile-loading functions)
# ---------------------------------------------------------------------------

$script:RepoRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent

# ---------------------------------------------------------------------------
# ConvertFrom-SimpleFrontmatter -- Minimal YAML parser
# ---------------------------------------------------------------------------

function ConvertFrom-SimpleFrontmatter {
    <#
    .SYNOPSIS
        Parses YAML frontmatter from a markdown file's content.
    .DESCRIPTION
        Handles the subset of YAML used in profile files:
          - String values: key: value
          - Inline empty arrays: key: []
          - String arrays: key:\n  - item
          - Object arrays: key:\n  - id: X\n    check: Y
        Returns a hashtable of parsed key-value pairs plus a Body key
        containing the markdown content after the frontmatter.
    .PARAMETER Content
        The full text content of a markdown file with YAML frontmatter.
    .OUTPUTS
        Hashtable with parsed frontmatter keys and a Body key.
    .EXAMPLE
        $parsed = ConvertFrom-SimpleFrontmatter (Get-Content profile.md -Raw)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    $result = @{}
    $body = ''

    # Split frontmatter from body
    if ($Content -notmatch '(?s)\A---\r?\n(.*?)\r?\n---\r?\n?(.*)') {
        # No frontmatter found -- entire content is body
        $result['Body'] = $Content
        return $result
    }

    $yamlBlock = $Matches[1]
    $body = $Matches[2]
    $result['Body'] = $body

    $lines = $yamlBlock -split '\r?\n'
    $i = 0

    while ($i -lt $lines.Count) {
        $line = $lines[$i]

        # Skip blank lines and comments
        if ($line -match '^\s*$' -or $line -match '^\s*#') {
            $i++
            continue
        }

        # Match a top-level key
        if ($line -match '^(\w[\w-]*):\s*(.*)$') {
            $key = $Matches[1]
            $value = $Matches[2].Trim()

            # Case 1: inline empty array -- key: []
            if ($value -eq '[]') {
                $result[$key] = @()
                $i++
                continue
            }

            # Case 2: inline scalar value -- key: value
            if ($value -ne '') {
                $result[$key] = $value
                $i++
                continue
            }

            # Case 3: value is on subsequent indented lines (list)
            $i++
            $items = [System.Collections.Generic.List[object]]::new()

            while ($i -lt $lines.Count) {
                $nextLine = $lines[$i]

                # Stop if we hit a non-indented line (next top-level key or blank)
                if ($nextLine -match '^\S' -or $nextLine -match '^\s*$') {
                    break
                }

                # List item: "  - something"
                if ($nextLine -match '^\s+-\s+(.+)$') {
                    $itemValue = $Matches[1]

                    # Check if this is an object item (has a colon): "  - id: value"
                    if ($itemValue -match '^(\w[\w-]*):\s*(.*)$') {
                        $obj = @{}
                        $obj[$Matches[1]] = $Matches[2].Trim()
                        $i++

                        # Collect continuation properties: "    key: value"
                        while ($i -lt $lines.Count) {
                            $propLine = $lines[$i]
                            # Continuation property (indented more than the dash)
                            if ($propLine -match '^\s{4,}(\w[\w-]*):\s*(.*)$') {
                                $obj[$Matches[1]] = $Matches[2].Trim()
                                $i++
                            } else {
                                break
                            }
                        }

                        $items.Add($obj)
                    } else {
                        # Plain string list item
                        $items.Add($itemValue)
                        $i++
                    }
                } else {
                    # Unexpected indented line -- skip
                    $i++
                }
            }

            $result[$key] = @($items)
            continue
        }

        # Unrecognized line -- skip
        $i++
    }

    return $result
}

# ---------------------------------------------------------------------------
# Get-ProfileFromFile -- Parse a single profile file
# ---------------------------------------------------------------------------

function Get-ProfileFromFile {
    <#
    .SYNOPSIS
        Parses a single profile markdown file into a structured hashtable.
    .DESCRIPTION
        Reads the specified profile file, extracts YAML frontmatter, and
        returns a normalized hashtable with typed fields. Missing optional
        fields default to empty arrays or empty strings.
    .PARAMETER Path
        Absolute or relative path to a profile .md file.
    .OUTPUTS
        Hashtable with keys: Name, Version, Description, Requires,
        WingetPackages, ManualInstalls, VSCodeExtensions, ClaudeSkills, Body.
    .EXAMPLE
        $profile = Get-ProfileFromFile -Path "profiles/go-cli.md"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        Write-Error "Profile file not found: $Path"
        return $null
    }

    $content = Get-Content -Path $Path -Raw
    $parsed = ConvertFrom-SimpleFrontmatter -Content $content

    # Normalize winget packages to array of hashtables with Id/Check/Note
    $wingetPackages = @()
    if ($parsed.ContainsKey('winget')) {
        $wingetPackages = @(foreach ($item in $parsed['winget']) {
            if ($item -is [hashtable]) {
                @{
                    Id    = if ($item.ContainsKey('id'))    { $item['id'] }    else { '' }
                    Check = if ($item.ContainsKey('check')) { $item['check'] } else { '' }
                    Note  = if ($item.ContainsKey('note'))  { $item['note'] }  else { '' }
                }
            }
        })
    }

    # Normalize manual installs to array of hashtables with Id/Check/Install/Note
    $manualInstalls = @()
    if ($parsed.ContainsKey('manual')) {
        $manualInstalls = @(foreach ($item in $parsed['manual']) {
            if ($item -is [hashtable]) {
                @{
                    Id      = if ($item.ContainsKey('id'))      { $item['id'] }      else { '' }
                    Check   = if ($item.ContainsKey('check'))   { $item['check'] }   else { '' }
                    Install = if ($item.ContainsKey('install')) { $item['install'] } else { '' }
                    Note    = if ($item.ContainsKey('note'))    { $item['note'] }    else { '' }
                }
            }
        })
    }

    # Normalize string arrays (default to empty, filter out nulls)
    $requires        = @(if ($parsed.ContainsKey('requires')          -and $null -ne $parsed['requires'])         { @($parsed['requires']) }         else { @() })
    $vsCodeExt       = @(if ($parsed.ContainsKey('vscode-extensions') -and $null -ne $parsed['vscode-extensions']){ @($parsed['vscode-extensions']) } else { @() })
    $claudeSkills    = @(if ($parsed.ContainsKey('claude-skills')     -and $null -ne $parsed['claude-skills'])    { @($parsed['claude-skills']) }    else { @() })

    return @{
        Name             = if ($parsed.ContainsKey('name'))        { $parsed['name'] }        else { '' }
        Version          = if ($parsed.ContainsKey('version'))     { $parsed['version'] }     else { '' }
        Description      = if ($parsed.ContainsKey('description')) { $parsed['description'] } else { '' }
        Requires         = $requires
        WingetPackages   = $wingetPackages
        ManualInstalls   = $manualInstalls
        VSCodeExtensions = $vsCodeExt
        ClaudeSkills     = $claudeSkills
        Body             = if ($parsed.ContainsKey('Body')) { $parsed['Body'] } else { '' }
    }
}

# ---------------------------------------------------------------------------
# Get-AllProfiles -- List and parse all profiles
# ---------------------------------------------------------------------------

function Get-AllProfiles {
    <#
    .SYNOPSIS
        Lists all profile files from the profiles/ directory and parses each one.
    .DESCRIPTION
        Scans the profiles/ directory at the repository root for .md files.
        Returns an array of parsed profile hashtables, one per file.
    .OUTPUTS
        Array of profile hashtables (same structure as Get-ProfileFromFile).
    .EXAMPLE
        $profiles = Get-AllProfiles
        $profiles | ForEach-Object { Write-Host $_.Name }
    #>
    [CmdletBinding()]
    param()

    $profileDir = Join-Path $script:RepoRoot 'profiles'
    if (-not (Test-Path $profileDir)) {
        Write-Warning "Profiles directory not found: $profileDir"
        return @()
    }

    $files = Get-ChildItem -Path $profileDir -Filter '*.md' -File | Sort-Object Name
    if ($files.Count -eq 0) {
        return @()
    }

    $profiles = [System.Collections.Generic.List[hashtable]]::new()
    foreach ($file in $files) {
        $profile = Get-ProfileFromFile -Path $file.FullName
        if ($null -ne $profile) {
            $profiles.Add($profile)
        }
    }

    return @($profiles)
}

# ---------------------------------------------------------------------------
# Get-Profile -- Get single profile by name
# ---------------------------------------------------------------------------

function Get-Profile {
    <#
    .SYNOPSIS
        Retrieves a single profile by name.
    .DESCRIPTION
        Searches the profiles/ directory for a file whose parsed name field
        matches the specified name, or whose filename (minus extension) matches.
        Returns the parsed profile hashtable or $null if not found.
    .PARAMETER Name
        The profile name to look up (e.g., "go-cli").
    .OUTPUTS
        Profile hashtable or $null.
    .EXAMPLE
        $profile = Get-Profile -Name "go-cli"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $profileDir = Join-Path $script:RepoRoot 'profiles'
    if (-not (Test-Path $profileDir)) {
        return $null
    }

    # Try exact filename match first (name.md)
    $directPath = Join-Path $profileDir "$Name.md"
    if (Test-Path $directPath) {
        return Get-ProfileFromFile -Path $directPath
    }

    # Fall back to scanning all profiles by parsed name field
    $files = Get-ChildItem -Path $profileDir -Filter '*.md' -File
    foreach ($file in $files) {
        $profile = Get-ProfileFromFile -Path $file.FullName
        if ($null -ne $profile -and $profile.Name -eq $Name) {
            return $profile
        }
    }

    return $null
}

# ---------------------------------------------------------------------------
# Resolve-ProfileDeps -- Dependency resolution with cycle detection
# ---------------------------------------------------------------------------

function Resolve-ProfileDeps {
    <#
    .SYNOPSIS
        Resolves profile dependencies and returns them in install order.
    .DESCRIPTION
        Given an array of profile names, recursively resolves the requires
        field for each profile and returns a flat, deduplicated list in
        topological (install) order. Dependencies come before dependents.
        Throws on circular dependencies.
    .PARAMETER Names
        Array of profile names to resolve.
    .OUTPUTS
        Array of profile name strings in install order.
    .EXAMPLE
        $order = Resolve-ProfileDeps -Names @("go-cli", "node-dev")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Names
    )

    # Load all available profiles into a lookup table
    $allProfiles = @{}
    $profileDir = Join-Path $script:RepoRoot 'profiles'
    if (Test-Path $profileDir) {
        $files = Get-ChildItem -Path $profileDir -Filter '*.md' -File
        foreach ($file in $files) {
            $profile = Get-ProfileFromFile -Path $file.FullName
            if ($null -ne $profile -and $profile.Name) {
                $allProfiles[$profile.Name] = $profile
            }
        }
    }

    $resolved = [System.Collections.Generic.List[string]]::new()
    $visiting = [System.Collections.Generic.HashSet[string]]::new()

    function Resolve-Single {
        param([string]$ProfileName)

        # Already in the output list -- skip
        if ($resolved.Contains($ProfileName)) {
            return
        }

        # Cycle detection: currently in the visit stack
        if ($visiting.Contains($ProfileName)) {
            throw "Circular dependency detected: '$ProfileName' is already in the dependency chain."
        }

        # Check that the profile exists
        if (-not $allProfiles.ContainsKey($ProfileName)) {
            throw "Profile not found: '$ProfileName'"
        }

        $null = $visiting.Add($ProfileName)

        # Recurse into dependencies first
        $deps = @($allProfiles[$ProfileName].Requires)
        foreach ($dep in $deps) {
            if ($dep -is [string] -and $dep -ne '') {
                Resolve-Single -ProfileName $dep
            }
        }

        $null = $visiting.Remove($ProfileName)
        $resolved.Add($ProfileName)
    }

    foreach ($name in $Names) {
        Resolve-Single -ProfileName $name
    }

    return @($resolved)
}
