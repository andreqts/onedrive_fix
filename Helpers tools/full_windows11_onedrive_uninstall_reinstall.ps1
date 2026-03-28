# TIP: before running this script, you can try running this from the Run dialog (Win + R) or PowerShell first:
#      %localappdata%\Microsoft\OneDrive\onedrive.exe /reset
# It usually works. If it doesn't, then you can try this full uninstall and reinstall running this script as admin.
# It uninstall OneDrive, removes all the local files and registry settings, then reinstalls it. 
# It does not touch your user's OneDrive folder in your profile, so no local files should be lost. 
# But it is highly recommended to backup your registry and important files before running this script, just in case.
# After running this script, you will need to restart Windows and launch OneDrive from the Start Menu to sign back in.
# Note: If you have OneDrive for Business, it will also be reinstalled and you will need to sign in again.

#Requires -RunAsAdministrator

Write-Host "=== Full OneDrive Reset and Reinstallation ===" -ForegroundColor Cyan

# 1. Stop all OneDrive-related processes
Write-Host "Stopping OneDrive processes..." -ForegroundColor Yellow
$processes = @("OneDrive", "OneDriveStandaloneUpdater", "FileSyncConfig", "FileCoAuth")

foreach ($p in $processes) {
    Get-Process -Name $p -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}

# Wait to ensure file locks are released
Start-Sleep -Seconds 2 

# 2. Uninstall OneDrive using winget (Improved parameters)
çWrite-Host "Uninstalling OneDrive via winget..." -ForegroundColor Yellow
# Using --id and --exact prevents winget from pausing if multiple packages match "Microsoft.OneDrive"
winget uninstall --id Microsoft.OneDrive --exact --silent --accept-source-agreements

# Give the background uninstaller a moment to finish
Start-Sleep -Seconds 5 

# 3. Clean up Registry Settings (Crucial for SQLite/DB corruption)
Write-Host "Clearing OneDrive Registry configurations..." -ForegroundColor Yellow
$regPath = "HKCU:\Software\Microsoft\OneDrive"
if (Test-Path $regPath) {
    Remove-Item -Path $regPath -Recurse -Force -ErrorAction SilentlyContinue
}

# 4. Remove leftover folders (Cache, DBs, and Binaries)
Write-Host "Removing leftover AppData and ProgramFiles folders..." -ForegroundColor Yellow
$pathsToRemove = @(
    "$env:LOCALAPPDATA\Microsoft\OneDrive",
    "$env:LOCALAPPDATA\OneDrive",
    "$env:PROGRAMDATA\Microsoft OneDrive",
    "$env:PROGRAMFILES\Microsoft OneDrive",
    "${env:ProgramFiles(x86)}\Microsoft OneDrive"
)

foreach ($path in $pathsToRemove) {
    if (Test-Path $path) {
        Write-Host " -> Removing: $path" -ForegroundColor DarkGray
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# 5. Ensure the user's OneDrive files folder is preserved
Write-Host "Preserved User Data Locations (Not deleted):" -ForegroundColor Green
Write-Host " -> $env:USERPROFILE\OneDrive" -ForegroundColor Green
# (Also implies preservation of "OneDrive - [Company Name]" if they use OneDrive for Business)

# 6. Reinstall OneDrive
Write-Host "Reinstalling OneDrive via winget..." -ForegroundColor Yellow
winget install --id Microsoft.OneDrive --exact --silent --accept-source-agreements --accept-package-agreements

Write-Host "Process completed successfully." -ForegroundColor Cyan
Write-Host "Please restart Windows, then launch OneDrive from the Start Menu to sign back in." -ForegroundColor Cyan