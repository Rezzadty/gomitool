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
    $backOption = $volumes.Count + 1
    Write-Host "  ${backOption}. Back to main menu" -ForegroundColor DarkYellow
    Write-Host ""
    $volChoice = Read-Host "Select a volume to scan for temporary files (1-${backOption})"

    if ($volChoice -eq "$backOption") { return }

    $volIndex = [int]$volChoice - 1
    if ($volIndex -lt 0 -or $volIndex -ge $volumes.Count) {
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
