# Scans a selected volume for temporary files
# Loops until user picks "Back to main menu", returns $true to reset main menu
function Scan-TempFiles {
    # Get volumes with drive letters
    $volumes = Get-Volume | Where-Object { $_.DriveLetter -ne $null }
    # "Back to main menu" is always the last option
    $backOption = $volumes.Count + 1
    $firstRun = $true

    # Keep looping until user goes back
    while ($true) {
        # First run clears screen, after that keeps results visible
        if ($firstRun) {
            Clear-Host
            Write-Host "=== Temporary File Scanner ===" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Available volumes:" -ForegroundColor Green
            Write-Host ""
            $firstRun = $false
        } else {
            Write-Host "=== Temporary File Scanner ===" -ForegroundColor Cyan
            Write-Host ""
        }

        # List volumes for user to pick
        $index = 1
        foreach ($vol in $volumes) {
            $label = if ($vol.FileSystemLabel) { $vol.FileSystemLabel } else { "No Label" }
            Write-Host "  $index. [$($vol.DriveLetter):] $label"
            $index++
        }
        Write-Host "  ${backOption}. Back to main menu" -ForegroundColor DarkYellow
        Write-Host ""
        $volChoice = Read-Host "Select a volume to scan for temporary files (1-${backOption})"

        # Return $true so main loop resets to full ASCII menu
        if ($volChoice -eq "$backOption") { return $true }

        # Convert 1-based input to 0-based array index
        $volIndex = [int]$volChoice - 1
        if ($volIndex -lt 0 -or $volIndex -ge $volumes.Count) {
            Write-Host "Invalid selection." -ForegroundColor Red
            Write-Host ""
            continue
        }

        $selectedVol = $volumes[$volIndex]
        $driveLetter = $selectedVol.DriveLetter
        Write-Host ""
        Write-Host "Scanning [${driveLetter}:] for temporary files..." -ForegroundColor Yellow
        Write-Host ""

        # Common temp file locations to scan
        $tempPaths = @(
            "${driveLetter}:\Windows\Temp",
            "${driveLetter}:\Users\*\AppData\Local\Temp",
            "${driveLetter}:\`$Recycle.Bin"
        )

        $totalFiles = 0
        $totalSizeMB = 0

        # Scan each temp path for files
        foreach ($path in $tempPaths) {
            # Resolve wildcards (*) into actual paths, skip if path doesn't exist
            $resolved = Resolve-Path -Path $path -ErrorAction SilentlyContinue
            if ($resolved) {
                foreach ($r in $resolved) {
                    if (Test-Path -LiteralPath $r.Path) {
                        # Get all files recursively, skip permission errors
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

        # Show summary
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
}
