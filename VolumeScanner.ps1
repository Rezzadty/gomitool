# Load external function scripts into current scope using dot-sourcing
# $PSScriptRoot = folder where this script lives
. "$PSScriptRoot\Scan\ScanVolumes.ps1"
. "$PSScriptRoot\Temp\ScanTempFiles.ps1"

# Main menu with ASCII banner, shown on first launch or returning from temp scanner
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

# Inline options without clearing screen, so previous output stays visible
function Show-Options {
    Write-Host "=== Volume Scanner ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Scan how many volumes this PC has" 
    Write-Host "2. Scan for temporary files in the volumes"
    Write-Host "3. Exit" 
    Write-Host ""
}

# Main loop - runs until user picks "3"
$choice = ""
$firstRun = $true
do {
    # Show full banner on first run, inline options after that
    if ($firstRun) {
        Show-Menu
        $firstRun = $false
    } else {
        Show-Options
    }
    # Wait for user input
    $choice = Read-Host "Select an option (1-3)"

    # Handle user choice
    switch ($choice) {
        "1" { Scan-Volumes }
        "2" {
            # Returns $true if user picked "Back to main menu"
            $backToMenu = Scan-TempFiles
            if ($backToMenu) { $firstRun = $true }
        }
        "3" { Write-Host "Goodbye!" -ForegroundColor Yellow }
        default { Write-Host "Invalid option. Try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
} while ($choice -ne "3")
