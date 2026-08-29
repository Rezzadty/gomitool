function Format-FileSize([double]$bytes) {
    if ($bytes -ge 1GB) { return "{0:N2} GB" -f ($bytes / 1GB) }
    if ($bytes -ge 1MB) { return "{0:N2} MB" -f ($bytes / 1MB) }
    if ($bytes -ge 1KB) { return "{0:N2} KB" -f ($bytes / 1KB) }
    return "{0} B" -f $bytes
}

function Remove-CategoryFiles($category, [string]$drive) {
    if ($category.Name -eq "Recycle Bin") {
        Clear-RecycleBin -DriveLetter $drive -Force -ErrorAction SilentlyContinue -Confirm:$false
        return
    }
    foreach ($p in $category.Paths) {
        $resolved = Resolve-Path -Path $p -ErrorAction SilentlyContinue
        if ($resolved) {
            foreach ($r in $resolved) {
                if (Test-Path -LiteralPath $r.Path) {
                    $item = Get-Item -LiteralPath $r.Path -Force -ErrorAction SilentlyContinue
                    if ($item.PSIsContainer) {
                        $files = Get-ChildItem -LiteralPath $r.Path -Force -Recurse -File -ErrorAction SilentlyContinue
                        foreach ($f in $files) {
                            try {
                                $stream = [System.IO.File]::Open($f.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
                                if ($stream) {
                                    $stream.Close()
                                    $stream.Dispose()
                                    Remove-Item -LiteralPath $f.FullName -Force -ErrorAction SilentlyContinue
                                }
                            } catch {
                                # In-use or locked file skipped safely
                            }
                        }
                        Get-ChildItem -LiteralPath $r.Path -Force -Recurse -Directory -ErrorAction SilentlyContinue |
                            Where-Object { (Get-ChildItem -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue).Count -eq 0 } |
                            Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                    } else {
                        try {
                            $stream = [System.IO.File]::Open($item.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
                            if ($stream) {
                                $stream.Close()
                                $stream.Dispose()
                                Remove-Item -LiteralPath $item.FullName -Force -ErrorAction SilentlyContinue
                            }
                        } catch {
                            # In-use or locked file skipped safely
                        }
                    }
                }
            }
        }
    }
}

function Scan-TempFiles {
    $volumes = Get-Volume | Where-Object { $_.DriveLetter -ne $null }
    $backOption = $volumes.Count + 1
    $firstRun = $true

    while ($true) {
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

        $index = 1
        foreach ($vol in $volumes) {
            $label = if ($vol.FileSystemLabel) { $vol.FileSystemLabel } else { "No Label" }
            Write-Host "  $index. [$($vol.DriveLetter):] $label"
            $index++
        }
        Write-Host "  ${backOption}. Back to main menu" -ForegroundColor DarkYellow
        Write-Host ""
        $volChoice = Read-Host "Select a volume to scan for temporary files (1-${backOption})"

        if ($volChoice -eq "$backOption") { return $true }

        $volIndex = [int]$volChoice - 1
        if ($volIndex -lt 0 -or $volIndex -ge $volumes.Count) {
            Write-Host "Invalid selection." -ForegroundColor Red
            Write-Host ""
            continue
        }

        $selectedVol = $volumes[$volIndex]
        $driveLetter = $selectedVol.DriveLetter
        $timestamp = (Get-Date).ToString("M/d/yyyy h:mm tt")
        Write-Host ""
        Write-Host "Last scanned at $timestamp" -ForegroundColor DarkGray
        Write-Host "Scanning [$($driveLetter):] for temporary files..." -ForegroundColor Yellow
        Write-Host ""

        $isSystemDrive = Test-Path -LiteralPath "${driveLetter}:\Windows\System32"

        if ($isSystemDrive) {
            $categories = @(
                @{
                    Name = "Recycle Bin"
                    Desc = "Deleted files waiting for permanent removal."
                    Selected = $true
                    Paths = @("${driveLetter}:\`$Recycle.Bin")
                },
                @{
                    Name = "Temporary files"
                    Desc = "App temp data left behind and safe to clear."
                    Selected = $true
                    Paths = @(
                        "${driveLetter}:\Windows\Temp",
                        "${driveLetter}:\Users\*\AppData\Local\Temp"
                    )
                },
                @{
                    Name = "Thumbnails"
                    Desc = "Cached preview images for fast explorer loading."
                    Selected = $true
                    Paths = @(
                        "${driveLetter}:\Users\*\AppData\Local\Microsoft\Windows\Explorer\thumbcache_*.db",
                        "${driveLetter}:\Users\*\AppData\Local\Microsoft\Windows\Explorer\iconcache_*.db"
                    )
                },
                @{
                    Name = "Delivery Optimization Files"
                    Desc = "Cached Windows update files for peer sharing."
                    Selected = $true
                    Paths = @(
                        "${driveLetter}:\Windows\SoftwareDistribution\DeliveryOptimization",
                        "${driveLetter}:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization"
                    )
                },
                @{
                    Name = "Downloads"
                    Desc = "Files stored in personal Downloads folder."
                    Selected = $false
                    Paths = @("${driveLetter}:\Users\*\Downloads")
                },
                @{
                    Name = "Windows error reports and feedback diagnostics"
                    Desc = "Crash logs and diagnostic data from system errors."
                    Selected = $true
                    Paths = @(
                        "${driveLetter}:\ProgramData\Microsoft\Windows\WER",
                        "${driveLetter}:\Users\*\AppData\Local\Microsoft\Windows\WER"
                    )
                },
                @{
                    Name = "DirectX Shader Cache"
                    Desc = "GPU shader cache created to speed up game load time."
                    Selected = $true
                    Paths = @(
                        "${driveLetter}:\Users\*\AppData\Local\D3DSCache",
                        "${driveLetter}:\Users\*\AppData\Local\NVIDIA\DXCache",
                        "${driveLetter}:\Users\*\AppData\Local\AMD\DxCache"
                    )
                },
                @{
                    Name = "Temporary Internet Files"
                    Desc = "Webpage cache and browser data for offline preview."
                    Selected = $true
                    Paths = @(
                        "${driveLetter}:\Users\*\AppData\Local\Microsoft\Windows\INetCache",
                        "${driveLetter}:\Users\*\AppData\Local\Microsoft\Windows\WebCache"
                    )
                }
            )
        } else {
            $categories = @(
                @{
                    Name = "Recycle Bin"
                    Desc = "Deleted files waiting for permanent removal."
                    Selected = $true
                    Paths = @("${driveLetter}:\`$Recycle.Bin")
                }
            )
        }

        $totalSizeBytes = 0
        $selectedSizeBytes = 0

        foreach ($cat in $categories) {
            $catFiles = 0
            $catBytes = 0

            foreach ($p in $cat.Paths) {
                $resolved = Resolve-Path -Path $p -ErrorAction SilentlyContinue
                if ($resolved) {
                    foreach ($r in $resolved) {
                        if (Test-Path -LiteralPath $r.Path) {
                            $item = Get-Item -LiteralPath $r.Path -Force -ErrorAction SilentlyContinue
                            if ($item.PSIsContainer) {
                                $files = Get-ChildItem -LiteralPath $r.Path -Force -Recurse -File -ErrorAction SilentlyContinue
                                if ($files) {
                                    $catFiles += ($files | Measure-Object).Count
                                    $catBytes += ($files | Measure-Object -Property Length -Sum).Sum
                                }
                            } else {
                                $catFiles += 1
                                $catBytes += $item.Length
                            }
                        }
                    }
                }
            }

            $cat.Files = $catFiles
            $cat.Bytes = $catBytes
            $totalSizeBytes += $catBytes
            if ($cat.Selected) {
                $selectedSizeBytes += $catBytes
            }

            $box = if ($cat.Selected) { "[x]" } else { "[ ]" }
            $sizeStr = Format-FileSize $catBytes

            Write-Host ("-" * 70) -ForegroundColor DarkGray
            Write-Host " $box " -NoNewline -ForegroundColor $(if ($cat.Selected) { "Green" } else { "DarkGray" })
            Write-Host "$($cat.Name)" -NoNewline -ForegroundColor White
            $spacing = 65 - $cat.Name.Length - $sizeStr.Length
            if ($spacing -lt 1) { $spacing = 1 }
            Write-Host (" " * $spacing) -NoNewline
            Write-Host "$sizeStr" -ForegroundColor Yellow

            Write-Host "     $($cat.Desc)" -ForegroundColor Gray
        }

        Write-Host ("=" * 70) -ForegroundColor DarkGray
        Write-Host "  Selected cleanup size : $(Format-FileSize $selectedSizeBytes)" -ForegroundColor Green
        Write-Host "  Total scanned size    : $(Format-FileSize $totalSizeBytes)" -ForegroundColor Yellow
        Write-Host ("=" * 70) -ForegroundColor DarkGray
        Write-Host ""

        if ($selectedSizeBytes -gt 0) {
            $cleanChoice = Read-Host "Clean up selected files? (Y/N)"
            if ($cleanChoice -match '^(y|yes)$') {
                Write-Host ""
                Write-Host "Cleaning up selected files on [$($driveLetter):]..." -ForegroundColor Yellow
                foreach ($cat in $categories) {
                    if ($cat.Selected -and $cat.Bytes -gt 0) {
                        Remove-CategoryFiles $cat $driveLetter
                    }
                }
                Write-Host "Cleanup complete." -ForegroundColor Green
                Write-Host ""
            }
        }
    }
}
