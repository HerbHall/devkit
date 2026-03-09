# Get-SystemConfig.ps1 — Comprehensive system config dump
# Run as Administrator in PowerShell

$outFile = "$env:USERPROFILE\Desktop\SystemConfig_$(hostname)_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

function Write-Section($title) {
    "`n$('='*60)" | Out-File $outFile -Append
    "  $title" | Out-File $outFile -Append
    "$('='*60)`n" | Out-File $outFile -Append
}

# Header
"System Configuration Report" | Out-File $outFile
"Generated: $(Get-Date)" | Out-File $outFile -Append
"Hostname: $(hostname)" | Out-File $outFile -Append

# OS Info
Write-Section "OPERATING SYSTEM"
Get-CimInstance Win32_OperatingSystem | Format-List Caption, Version, BuildNumber, OSArchitecture, InstallDate, LastBootUpTime | Out-File $outFile -Append

# CPU
Write-Section "PROCESSOR"
Get-CimInstance Win32_Processor | Format-List Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed, CurrentClockSpeed, L2CacheSize, L3CacheSize | Out-File $outFile -Append

# Motherboard & BIOS
Write-Section "MOTHERBOARD & BIOS"
Get-CimInstance Win32_BaseBoard | Format-List Manufacturer, Product, Version, SerialNumber | Out-File $outFile -Append
Get-CimInstance Win32_BIOS | Format-List Manufacturer, SMBIOSBIOSVersion, ReleaseDate | Out-File $outFile -Append

# Memory
Write-Section "MEMORY"
$totalRAM = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
"Total Physical Memory: {0:N2} GB" -f ($totalRAM / 1GB) | Out-File $outFile -Append
"`nDIMM Details:" | Out-File $outFile -Append
Get-CimInstance Win32_PhysicalMemory | Format-Table DeviceLocator, Manufacturer, PartNumber, @{N='Capacity(GB)';E={$_.Capacity/1GB}}, Speed, ConfiguredClockSpeed, ConfiguredVoltage -AutoSize | Out-File $outFile -Append -Width 200

# GPU
Write-Section "GPU"
Get-CimInstance Win32_VideoController | Format-List Name, DriverVersion, DriverDate, AdapterRAM, VideoProcessor, CurrentHorizontalResolution, CurrentVerticalResolution, CurrentRefreshRate | Out-File $outFile -Append
try {
    "`nNVIDIA SMI Output:" | Out-File $outFile -Append
    nvidia-smi | Out-File $outFile -Append
} catch { "nvidia-smi not available" | Out-File $outFile -Append }

# Storage - Physical Disks
Write-Section "STORAGE - PHYSICAL DISKS"
Get-PhysicalDisk | Format-Table FriendlyName, MediaType, @{N='Size(GB)';E={[math]::Round($_.Size/1GB,1)}}, BusType, HealthStatus, OperationalStatus -AutoSize | Out-File $outFile -Append -Width 200

# Storage - Volumes
"`nVolumes:" | Out-File $outFile -Append
Get-Volume | Where-Object DriveLetter | Format-Table DriveLetter, FileSystemLabel, FileSystem, @{N='Size(GB)';E={[math]::Round($_.Size/1GB,1)}}, @{N='Free(GB)';E={[math]::Round($_.SizeRemaining/1GB,1)}}, HealthStatus -AutoSize | Out-File $outFile -Append -Width 200

# Storage - NVMe details
"`nNVMe Details:" | Out-File $outFile -Append
Get-PhysicalDisk | Where-Object BusType -eq 'NVMe' | ForEach-Object {
    $disk = $_
    Get-StorageReliabilityCounter -PhysicalDisk $disk -ErrorAction SilentlyContinue | Format-List @{N='Disk';E={$disk.FriendlyName}}, Temperature, Wear, ReadErrorsTotal, WriteErrorsTotal | Out-File $outFile -Append
}

# Network Adapters
Write-Section "NETWORK ADAPTERS"
Get-NetAdapter | Where-Object Status -eq 'Up' | Format-Table Name, InterfaceDescription, LinkSpeed, MacAddress -AutoSize | Out-File $outFile -Append -Width 200
"`nIP Configuration:" | Out-File $outFile -Append
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notmatch '^169\.' -and $_.IPAddress -ne '127.0.0.1' } | Format-Table InterfaceAlias, IPAddress, PrefixLength -AutoSize | Out-File $outFile -Append -Width 200
"`nDNS Servers:" | Out-File $outFile -Append
Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object ServerAddresses | Format-Table InterfaceAlias, ServerAddresses -AutoSize | Out-File $outFile -Append -Width 200

# Power Configuration
Write-Section "POWER CONFIGURATION"
powercfg /getactivescheme | Out-File $outFile -Append
"`nAll Power Schemes:" | Out-File $outFile -Append
powercfg /list | Out-File $outFile -Append

# Windows Features & Settings
Write-Section "WINDOWS SETTINGS"
"Game Mode: " + (Get-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -ErrorAction SilentlyContinue).AllowAutoGameMode | Out-File $outFile -Append
"Hardware-Accelerated GPU Scheduling: " + (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -ErrorAction SilentlyContinue).HwSchMode | Out-File $outFile -Append
"VBS (Virtualization-Based Security):" | Out-File $outFile -Append
Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -ErrorAction SilentlyContinue | Format-List VirtualizationBasedSecurityStatus, RequiredSecurityProperties, AvailableSecurityProperties | Out-File $outFile -Append

# Startup Programs
Write-Section "STARTUP PROGRAMS"
Get-CimInstance Win32_StartupCommand | Format-Table Name, Command, Location -AutoSize -Wrap | Out-File $outFile -Append -Width 200

# Installed Software (key items)
Write-Section "INSTALLED SOFTWARE (Filtered)"
$keywords = @('NVIDIA', 'ASUS', 'Docker', 'Visual Studio', 'Git', 'Go ', 'Golang', 'Python', 'Node', 'Tailscale', 'Steam', 'Epic', 'Armoury', 'Claude', 'Ollama', 'LM Studio')
$apps = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
    Where-Object { $n = $_.DisplayName; $n -and ($keywords | Where-Object { $n -match $_ }) } |
    Select-Object DisplayName, DisplayVersion, Publisher |
    Sort-Object DisplayName -Unique
$apps | Format-Table -AutoSize -Wrap | Out-File $outFile -Append -Width 200

# Services of interest
Write-Section "RELEVANT SERVICES"
$svcKeywords = @('Docker', 'NVIDIA', 'Tailscale', 'SSH', 'Ollama', 'Home Assistant')
Get-Service | Where-Object { $n = $_.DisplayName; $svcKeywords | Where-Object { $n -match $_ } } | Format-Table Name, DisplayName, Status, StartType -AutoSize | Out-File $outFile -Append -Width 200

# Resizable BAR check
Write-Section "RESIZABLE BAR / ABOVE 4G DECODING"
try {
    $rebarState = (nvidia-smi --query-gpu=gpu_name,pci.bus_id,bar1.total --format=csv,noheader 2>$null)
    "nvidia-smi BAR1 info: $rebarState" | Out-File $outFile -Append
} catch { "Could not query ReBAR status via nvidia-smi" | Out-File $outFile -Append }

# Finish
Write-Section "END OF REPORT"
Write-Host "`nConfig saved to: $outFile" -ForegroundColor Green
Write-Host "Please share this file with Claude." -ForegroundColor Yellow

# Open the file
notepad $outFile
