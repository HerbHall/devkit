<#
.SYNOPSIS
    Template for creating Windows Explorer context menu entries.
    
.DESCRIPTION
    This script demonstrates the correct way to add context menu entries
    to Windows Explorer using PowerShell's native registry provider.
    
    Key principles:
    - Uses New-Item/Set-ItemProperty instead of reg.exe (preserves quotes)
    - Handles both Directory\shell and Directory\Background\shell
    - Properly quotes paths with %1 and %V variables
    
.NOTES
    Run as Administrator
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = "Continue"

# ============================================
# CONFIGURATION - Edit this section
# ============================================

$MenuItems = @(
    @{
        Key = "MyApp_01"                          # Unique registry key name
        Name = "Open in My App"                   # Display name in context menu
        Icon = "C:\Path\To\app.exe"              # Icon source (exe or ico)
        CmdBg = 'myapp.exe --dir "%V"'           # Command for background click
        CmdDir = 'myapp.exe --dir "%1"'          # Command for folder click
    }
    # Add more entries here...
)

# ============================================
# CLEANUP - Remove existing entries
# ============================================

Write-Host "Cleaning up old entries..." -ForegroundColor Yellow

foreach ($item in $MenuItems) {
    $key = $item.Key
    Remove-Item -Path "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\$key" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\$key" -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "Done." -ForegroundColor Green

# ============================================
# INSTALL - Create new entries
# ============================================

Write-Host "Installing context menu entries..." -ForegroundColor Yellow

foreach ($item in $MenuItems) {
    $key = $item.Key
    $name = $item.Name
    $icon = $item.Icon
    $cmdBg = $item.CmdBg
    $cmdDir = $item.CmdDir
    
    Write-Host "  Adding: $name" -ForegroundColor Gray
    
    # Directory Background (right-click in empty space inside folder)
    $bgPath = "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\$key"
    $null = New-Item -Path $bgPath -Force
    Set-ItemProperty -Path $bgPath -Name "(Default)" -Value $name
    Set-ItemProperty -Path $bgPath -Name "Icon" -Value $icon
    $null = New-Item -Path "$bgPath\command" -Force
    Set-ItemProperty -Path "$bgPath\command" -Name "(Default)" -Value $cmdBg
    
    # Directory (right-click on a folder)
    $dirPath = "Registry::HKEY_CLASSES_ROOT\Directory\shell\$key"
    $null = New-Item -Path $dirPath -Force
    Set-ItemProperty -Path $dirPath -Name "(Default)" -Value $name
    Set-ItemProperty -Path $dirPath -Name "Icon" -Value $icon
    $null = New-Item -Path "$dirPath\command" -Force
    Set-ItemProperty -Path "$dirPath\command" -Name "(Default)" -Value $cmdDir
}

Write-Host "Done." -ForegroundColor Green

# ============================================
# VERIFY
# ============================================

Write-Host "`nVerifying installation..." -ForegroundColor Yellow

foreach ($item in $MenuItems) {
    $key = $item.Key
    $cmdPath = "HKEY_CLASSES_ROOT\Directory\shell\$key\command"
    $result = reg query $cmdPath 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK: $($item.Name)" -ForegroundColor Green
        Write-Host "      $result" -ForegroundColor DarkGray
    } else {
        Write-Host "  FAILED: $($item.Name)" -ForegroundColor Red
    }
}

Write-Host "`nComplete! Restart Explorer if items don't appear:" -ForegroundColor Cyan
Write-Host "  taskkill /f /im explorer.exe; Start-Process explorer.exe" -ForegroundColor Gray
