# Displays detailed info for all volumes that have a drive letter
function Scan-Volumes {
    # Get only volumes with drive letters, skip hidden partitions
    $volumes = Get-Volume | Where-Object { $_.DriveLetter -ne $null }
    Write-Host ""
    Write-Host "Found $($volumes.Count) volume(s):" -ForegroundColor Green
    Write-Host ""
    Write-Host ("-" * 70) -ForegroundColor DarkGray
    $index = 1
    foreach ($vol in $volumes) {
        # Convert bytes to GB
        $sizeGB = [math]::Round($vol.Size / 1GB, 2)
        $freeGB = [math]::Round($vol.SizeRemaining / 1GB, 2)
        $usedGB = [math]::Round(($vol.Size - $vol.SizeRemaining) / 1GB, 2)
        # Avoid divide-by-zero on empty volumes
        if ($vol.Size -gt 0) {
            $usedPercent = [math]::Round((($vol.Size - $vol.SizeRemaining) / $vol.Size) * 100, 1)
        } else {
            $usedPercent = 0
        }
        # Show "No Label" if volume has no name
        $label = if ($vol.FileSystemLabel) { $vol.FileSystemLabel } else { "No Label" }
        $driveType = $vol.DriveType
        $fileSystem = $vol.FileSystem
        $health = $vol.HealthStatus

        # Display volume details
        Write-Host "  Volume $index : [$($vol.DriveLetter):]" -ForegroundColor Yellow
        Write-Host "    Label       : $label"
        Write-Host "    File System : $fileSystem"
        Write-Host "    Drive Type  : $driveType"
        Write-Host "    Health      : $health"
        Write-Host "    Total Size  : ${sizeGB} GB"
        Write-Host "    Used        : ${usedGB} GB (${usedPercent}%)"
        Write-Host "    Free        : ${freeGB} GB"
        Write-Host ("-" * 70) -ForegroundColor DarkGray
        $index++
    }
    Write-Host ""
}
