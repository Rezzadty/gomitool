# GOMITools

A simple PowerShell CLI tool that scans and displays volume (disk) information on your PC.

## What it does

- Scans all volumes on your PC and shows detailed info (label, file system, drive type, health, size, used/free space)
- Scans a selected volume for temporary files that can be cleaned up (Windows Temp, User Temp, Recycle Bin)
- Interactive menu so you can keep using it without restarting

## How to run

```powershell
.\VolumeScanner.ps1
```

## Menu Options

| Option | Description |
|--------|-------------|
| 1 | Scan how many volumes the PC has and display details |
| 2 | Scan a selected volume for temporary files |
| 3 | Exit |

## Requirements

- Windows OS
- PowerShell 5.1 or later
