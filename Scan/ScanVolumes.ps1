# Scans all volumes with a drive letter and displays detailed info (label, file system, drive type, health, size, used, free)
function Scan-Volumes {
    $volumes = Get-Volume | Where-Object { $_.DriveLetter -ne $null }
    Write-Host ""
    Write-Host "Found $($volumes.Count) volume(s):" -ForegroundColor Green
    Write-Host ""
    Write-Host ("-" * 70) -ForegroundColor DarkGray
    $index = 1
    # Convert sizes to GB and calculate used percentage, then display all relevant information for each volume
    foreach ($vol in $volumes) {
        $sizeGB = [math]::Round($vol.Size / 1GB, 2)
        $freeGB = [math]::Round($vol.SizeRemaining / 1GB, 2)
        $usedGB = [math]::Round(($vol.Size - $vol.SizeRemaining) / 1GB, 2)
        if ($vol.Size -gt 0) {
            $usedPercent = [math]::Round((($vol.Size - $vol.SizeRemaining) / $vol.Size) * 100, 1)
        } else {
            $usedPercent = 0
        }
        # Labeling volumes with no label as "No Label" for clarity
        $label = if ($vol.FileSystemLabel) { $vol.FileSystemLabel } else { "No Label" }
        $driveType = $vol.DriveType
        $fileSystem = $vol.FileSystem
        $health = $vol.HealthStatus

        # Displaying the information for each volume in a structured format
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
