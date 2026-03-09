Write-Host "=== DEVICES WITH PROBLEMS ==="
Get-CimInstance Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 } | ForEach-Object {
    Write-Host "---"
    Write-Host "Name: $($_.Name)"
    Write-Host "Status: $($_.Status) (Error: $($_.ConfigManagerErrorCode))"
    Write-Host "DeviceID: $($_.DeviceID)"
    Write-Host "Class: $($_.PNPClass)"
    # Get hardware IDs
    $hwIds = (Get-PnpDeviceProperty -InstanceId $_.DeviceID -KeyName DEVPKEY_Device_HardwareIds -ErrorAction SilentlyContinue).Data
    if ($hwIds) {
        Write-Host "HardwareIDs:"
        $hwIds | ForEach-Object { Write-Host "  $_" }
    }
    $compatible = (Get-PnpDeviceProperty -InstanceId $_.DeviceID -KeyName DEVPKEY_Device_CompatibleIds -ErrorAction SilentlyContinue).Data
    if ($compatible) {
        Write-Host "CompatibleIDs:"
        $compatible | ForEach-Object { Write-Host "  $_" }
    }
    $loc = (Get-PnpDeviceProperty -InstanceId $_.DeviceID -KeyName DEVPKEY_Device_LocationInfo -ErrorAction SilentlyContinue).Data
    if ($loc) { Write-Host "Location: $loc" }
    Write-Host ""
}
