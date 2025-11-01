# Github Hosts Update Script

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  Github Hosts Update Script" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$hostsPath = "$env:SystemRoot\System32\Drivers\etc\hosts"

# Try multiple GitHub hosts sources
$hostsSources = @(
    "https://github-hosts.tinsfox.com/hosts",
    "https://raw.hellogithub.com/hosts",
    "https://cdn.jsdelivr.net/gh/521xueweihan/GitHub520@main/hosts",
    "https://raw.githubusercontent.com/521xueweihan/GitHub520/main/hosts"
   
)

$apiUrl = $hostsSources[0]  # Use first source as primary

if (-not (Test-Path $hostsPath)) {
    Write-Host "Error: Cannot find hosts file: $hostsPath" -ForegroundColor Red
    exit 1
}

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Requesting administrator privileges..." -ForegroundColor Yellow
    Write-Host "Please click 'Yes' in the UAC prompt" -ForegroundColor Yellow
    Write-Host ""
    try {
        $scriptPath = $PSCommandPath
        Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-NoExit", "-File", $scriptPath -Verb RunAs
    }
    catch {
        Write-Host "Error: Failed to obtain administrator privileges" -ForegroundColor Red
    }
    exit
}

Write-Host "Administrator privileges obtained" -ForegroundColor Green
Write-Host ""

Write-Host "[1/4] Getting latest Github HOSTS..." -ForegroundColor Yellow

# Try multiple sources until one works
$hostsContent = $null
foreach ($source in $hostsSources) {
    try {
        Write-Host "Trying source: $source" -ForegroundColor Gray
        $headers = @{
            'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
        $response = Invoke-WebRequest -Uri $source -TimeoutSec 10 -UseBasicParsing -Headers $headers
        
        # Ensure content is decoded as string
        if ($response.Content -is [byte[]]) {
            $enc = [System.Text.Encoding]::UTF8
            $hostsContent = $enc.GetString($response.Content)
        } else {
            $hostsContent = [string]$response.Content
        }
        
        # Filter only lines with IP and github/vscode (exclude comments)
        $lines = $hostsContent -split "`n" | Where-Object { 
            $line = $_.ToString().Trim()
            $line -ne "" -and $line -notmatch '^#' -and $line -match '^\d+\.\d+\.\d+\.\d+\s+.*(?:github|vscode\.dev).*$' 
        }
        
        if ($lines.Count -gt 0) {
            # Ensure hostsContent is a string
            $hostsContent = [string]::Join("`n", $lines)
            Write-Host "Successfully got HOSTS from: $source" -ForegroundColor Green
            break
        }
    }
    catch {
        Write-Host "Failed to get from: $source" -ForegroundColor Yellow
        continue
    }
}

# Ensure hostsContent is a string before checking
$hostsContent = [string]$hostsContent

if ($null -eq $hostsContent -or $hostsContent.Trim() -eq "") {
    Write-Host "Error: Cannot get HOSTS from any source" -ForegroundColor Red
    Write-Host "Please check your internet connection" -ForegroundColor Red
    exit 1
}

Write-Host "Successfully got HOSTS content (length: $($hostsContent.Length) chars)" -ForegroundColor Green

Write-Host ""

Write-Host "[2/4] Reading current hosts file..." -ForegroundColor Yellow

try {
    $currentHosts = Get-Content $hostsPath -Raw -ErrorAction Stop
    $currentHosts = $currentHosts -replace "`r", ""
}
catch {
    Write-Host "Error: Cannot read hosts file" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "Successfully read hosts file" -ForegroundColor Green
Write-Host ""

Write-Host "[3/4] Processing hosts file content..." -ForegroundColor Yellow

$beginMarker = "#github-host begin"
$endMarker = "#github-host end"

$escapedBeginMarker = [regex]::Escape($beginMarker)
$escapedEndMarker = [regex]::Escape($endMarker)

# Use simple string manipulation to remove old github-host section
if ($currentHosts -match [regex]::Escape($beginMarker)) {
    Write-Host "Found existing github-host section, will be replaced" -ForegroundColor Yellow
    
    # Find the begin marker position
    $beginPos = $currentHosts.IndexOf($beginMarker)
    if ($beginPos -ge 0) {
        # Get content before begin marker
        $beforeContent = $currentHosts.Substring(0, $beginPos).TrimEnd()
        
        # Find end marker position
        $endPos = $currentHosts.IndexOf($endMarker, $beginPos)
        if ($endPos -ge 0) {
            # Get content after end marker
            $afterContent = $currentHosts.Substring($endPos + $endMarker.Length).TrimStart()
            $currentHosts = $beforeContent + "`n" + $afterContent
        } else {
            # No end marker found, just remove from begin marker
            $currentHosts = $beforeContent
        }
    }
}

$currentHosts = $currentHosts.TrimEnd("`n", "`r", " ")

Write-Host "[4/4] Backing up original hosts file..." -ForegroundColor Yellow

# Get script directory - compatible with both .ps1 and .exe execution
$scriptDir = $null
try {
    if ($PSScriptRoot -and $PSScriptRoot -ne "") {
        $scriptDir = $PSScriptRoot
    } elseif ($MyInvocation.MyCommand.Path -and $MyInvocation.MyCommand.Path -ne "") {
        $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    } elseif ($PSCommandPath -and $PSCommandPath -ne "") {
        $scriptDir = Split-Path -Parent $PSCommandPath
    } else {
        # For .exe files, use the current working directory
        $scriptDir = Get-Location
    }
} catch {
    # Fallback to current directory
    $scriptDir = Get-Location
}

# If scriptDir is still null or empty, use current directory
if (-not $scriptDir -or $scriptDir -eq "") {
    $scriptDir = Get-Location
}

# Create backup folder if it doesn't exist
$backupFolder = Join-Path $scriptDir "backup"
Write-Host "Script directory: $scriptDir" -ForegroundColor Gray
Write-Host "Backup folder: $backupFolder" -ForegroundColor Gray

if (-not (Test-Path $backupFolder)) {
    try {
        New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
        Write-Host "Created backup folder: $backupFolder" -ForegroundColor Gray
    } catch {
        Write-Host "Warning: Failed to create backup folder: $backupFolder" -ForegroundColor Yellow
        Write-Host "Will try to save backup in current directory" -ForegroundColor Yellow
        $backupFolder = $scriptDir
    }
}

$backupFileName = "hosts_backup_$(Get-Date -Format 'yyyy-MM-dd_HH.mm.ss').txt"
# Use string concatenation instead of Join-Path to avoid issues in .exe environment
if ($backupFolder -match '\\$') {
    $backupPath = $backupFolder + $backupFileName
} else {
    $backupPath = $backupFolder + "\" + $backupFileName
}

Write-Host "Backup file path: $backupPath" -ForegroundColor Gray

try {
    Copy-Item $hostsPath -Destination $backupPath -Force -ErrorAction Stop
    Write-Host "Backup saved to: $backupPath" -ForegroundColor Green
}
catch {
    Write-Host "Warning: Cannot create backup file" -ForegroundColor Yellow
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Source: $hostsPath" -ForegroundColor Gray
    Write-Host "Destination: $backupPath" -ForegroundColor Gray
}

Write-Host ""

$newHosts = $currentHosts

if ($newHosts -ne "") {
    $newHosts += "`n`n"
}

$newHosts += "$beginMarker`n"
# Ensure hostsContent is string before using Trim()
$newHosts += [string]$hostsContent.Trim()
$newHosts += "`n$endMarker"

Write-Host "Writing new hosts file..." -ForegroundColor Yellow

try {
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllLines($hostsPath, $newHosts.Split("`n"), $utf8NoBom)
    
    Write-Host "Hosts file updated successfully!" -ForegroundColor Green
}
catch {
    Write-Host "Error: Cannot write hosts file" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Flushing DNS cache..." -ForegroundColor Yellow

try {
    ipconfig /flushdns | Out-Null
    Write-Host "DNS cache flushed successfully!" -ForegroundColor Green
}
catch {
    Write-Host "Warning: Failed to flush DNS cache. You may need to run 'ipconfig /flushdns' manually." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  Operation complete! Opening hosts file with Notepad" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

Start-Process notepad.exe -ArgumentList $hostsPath

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
try {
    if ($Host.Name -eq 'ConsoleHost') {
        $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
    } else {
        Start-Sleep -Seconds 10
    }
}
catch {
    Start-Sleep -Seconds 10
}
