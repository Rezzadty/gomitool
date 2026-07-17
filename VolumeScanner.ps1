function Show-Menu {
    Clear-Host
    Write-Host " ____   ___   __  __  ___ " -ForegroundColor Magenta
    Write-Host "/ ___|/ _ \ |  \/  |[_ _|" -ForegroundColor Magenta
    Write-Host "| |_ | | | || |\/| | | | " -ForegroundColor Magenta
    Write-Host "| |_|| |_| || |  | | | | " -ForegroundColor Magenta
    Write-Host "\___| \____||_|  |_|[___|" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "=== Volume Scanner ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Scan how many volumes this PC has"
    Write-Host "2. Scan for temporary files in the volumes"
    Write-Host "3. Exit"
    Write-Host ""
}

# Scans all volumes with a drive letter and displays detailed info (label, file system, drive type, health, size, used, free)
function Scan-Volumes {
    $volumes = Get-Volume | Where-Object { $_.DriveLetter -ne $null } # Get all volumes that have a drive letter assigned
    Write-Host ""
    Write-Host "Found $($volumes.Count) volume(s):" -ForegroundColor Green # Display the number of volumes found
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

# Shows the option list again so the user can interact after viewing results
function Show-Options {
    Write-Host "=== Volume Scanner ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Scan how many volumes this PC has" 
    Write-Host "2. Scan for temporary files in the volumes"
    Write-Host "3. Exit" 
    Write-Host ""
}

# Scans a selected volume for temporary files and displays file count and total size
function Scan-TempFiles {
    $volumes = Get-Volume | Where-Object { $_.DriveLetter -ne $null }
    Write-Host ""
    Write-Host "Available volumes:" -ForegroundColor Green
    $index = 1
    foreach ($vol in $volumes) {
        $label = if ($vol.FileSystemLabel) { $vol.FileSystemLabel } else { "No Label" }
        Write-Host "  $index. [$($vol.DriveLetter):] $label"
        $index++
    }
    Write-Host ""
    Write-Host "  1. Back to main menu" -ForegroundColor DarkYellow
    Write-Host ""
    $volChoice = Read-Host "Select a volume to scan for temporary files (0 to go back, 2-$($volumes.Count))"

    if ($volChoice -eq "1") { return }

    $volIndex = [int]$volChoice - 1
    if ($volIndex -lt 1 -or $volIndex -ge $volumes.Count) {
        Write-Host "Invalid selection." -ForegroundColor Red
        return
    }

    $selectedVol = $volumes[$volIndex]
    $driveLetter = $selectedVol.DriveLetter
    Write-Host ""
    Write-Host "Scanning [${driveLetter}:] for temporary files..." -ForegroundColor Yellow
    Write-Host ""

    $tempPaths = @(
        "${driveLetter}:\Windows\Temp",
        "${driveLetter}:\Users\*\AppData\Local\Temp",
        "${driveLetter}:\`$Recycle.Bin"
    )

    $totalFiles = 0
    $totalSizeMB = 0

    foreach ($path in $tempPaths) {
        $resolved = Resolve-Path -Path $path -ErrorAction SilentlyContinue
        if ($resolved) {
            foreach ($r in $resolved) {
                if (Test-Path -LiteralPath $r.Path) {
                    $files = Get-ChildItem -Path $r.Path -Recurse -File -ErrorAction SilentlyContinue
                    $count = ($files | Measure-Object).Count
                    $sizeMB = [math]::Round(($files | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
                    if ($count -gt 0) {
                        Write-Host "  $($r.Path)" -ForegroundColor Cyan
                        Write-Host "    Files : $count"
                        Write-Host "    Size  : ${sizeMB} MB"
                        Write-Host ""
                        $totalFiles += $count
                        $totalSizeMB += $sizeMB
                    }
                }
            }
        }
    }

    Write-Host ("-" * 70) -ForegroundColor DarkGray
    if ($totalFiles -eq 0) {
        Write-Host "  No temporary files found on [${driveLetter}:]" -ForegroundColor Green
    } else {
        Write-Host "  Total temporary files : $totalFiles" -ForegroundColor Yellow
        Write-Host "  Total size            : ${totalSizeMB} MB" -ForegroundColor Yellow
    }
    Write-Host ("-" * 70) -ForegroundColor DarkGray
    Write-Host ""
}

# Main loop - shows menu, handles user input, and loops until user chooses to exit
do {
    Show-Menu
    $choice = Read-Host "Select an option (1-3)"

    switch ($choice) {
        "1" {
            Scan-Volumes
            Show-Options
            $choice = Read-Host "Select an option (1-3)"
            while ($choice -eq "1") {
                Scan-Volumes
                Show-Options
                $choice = Read-Host "Select an option (1-3)"
            }
            if ($choice -eq "3") { Write-Host "Goodbye!" -ForegroundColor Yellow }
        }
        "2" {
            Scan-TempFiles
            Show-Options
            $choice = Read-Host "Select an option (1-3)"
            while ($choice -eq "2") {
                Scan-TempFiles
                Show-Options
                $choice = Read-Host "Select an option (1-3)"
            }
            if ($choice -eq "3") { Write-Host "Goodbye!" -ForegroundColor Yellow }
        }
        "3" { Write-Host "Goodbye!" -ForegroundColor Yellow }
        default { Write-Host "Invalid option. Try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
} while ($choice -ne "3")
