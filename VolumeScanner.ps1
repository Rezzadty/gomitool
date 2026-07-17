# Dot-source the feature scripts
. "$PSScriptRoot\Scan\ScanVolumes.ps1"
. "$PSScriptRoot\Temp\ScanTempFiles.ps1"

# Displays the main menu with ASCII banner and available options
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

# Shows the option list again so the user can interact after viewing results
function Show-Options {
    Write-Host "=== Volume Scanner ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Scan how many volumes this PC has" 
    Write-Host "2. Scan for temporary files in the volumes"
    Write-Host "3. Exit" 
    Write-Host ""
}

# Main loop - shows menu, handles user input, and loops until user chooses to exit
$choice = ""
$firstRun = $true
do {
    if ($firstRun) {
        Show-Menu
        $firstRun = $false
    } else {
        Show-Options
    }
    $choice = Read-Host "Select an option (1-3)"

    switch ($choice) {
        "1" { Scan-Volumes }
        "2" { Scan-TempFiles }
        "3" { Write-Host "Goodbye!" -ForegroundColor Yellow }
        default { Write-Host "Invalid option. Try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
} while ($choice -ne "3")
