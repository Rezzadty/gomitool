$repoBase = "https://raw.githubusercontent.com/Rezzadty/gomitool/main"
$tempDir = Join-Path $env:TEMP "gomitool"

New-Item -ItemType Directory -Force -Path "$tempDir\Scan", "$tempDir\Temp" | Out-Null

Invoke-RestMethod "$repoBase/Scan/ScanVolumes.ps1" -OutFile "$tempDir\Scan\ScanVolumes.ps1"
Invoke-RestMethod "$repoBase/Temp/ScanTempFiles.ps1" -OutFile "$tempDir\Temp\ScanTempFiles.ps1"
Invoke-RestMethod "$repoBase/VolumeScanner.ps1" -OutFile "$tempDir\VolumeScanner.ps1"

& "$tempDir\VolumeScanner.ps1"
