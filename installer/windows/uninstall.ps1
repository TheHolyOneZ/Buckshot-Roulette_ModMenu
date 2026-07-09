#Requires -Version 5.1
param(
    [string]$GameDir = ""
)

$ErrorActionPreference = "Stop"
$ExeName = "Buckshot Roulette.exe"

function Say($msg) { Write-Host "[modmenu] $msg" -ForegroundColor Cyan }
function Err($msg) { Write-Host "[error] $msg" -ForegroundColor Red }
function Die($msg) { Err $msg; exit 1 }

function Find-SteamLibraries {
    $libs = New-Object System.Collections.Generic.List[string]
    $steamPath = $null
    foreach ($key in @("HKCU:\Software\Valve\Steam", "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam", "HKLM:\SOFTWARE\Valve\Steam")) {
        if (Test-Path $key) {
            $prop = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
            if ($prop.SteamPath)  { $steamPath = $prop.SteamPath }
            elseif ($prop.InstallPath) { $steamPath = $prop.InstallPath }
            if ($steamPath) { break }
        }
    }
    if (-not $steamPath) { return $libs }
    $steamPath = $steamPath -replace '/', '\'
    $libs.Add($steamPath)
    $vdf = Join-Path $steamPath "steamapps\libraryfolders.vdf"
    if (Test-Path $vdf) {
        $content = Get-Content $vdf -Raw
        $matches = [regex]::Matches($content, '"path"\s*"([^"]+)"')
        foreach ($m in $matches) {
            $p = $m.Groups[1].Value -replace '\\\\', '\'
            if ($libs -notcontains $p) { $libs.Add($p) }
        }
    }
    return $libs
}

if ([string]::IsNullOrWhiteSpace($GameDir)) {
    Say "No path given - searching Steam libraries..."
    $found = $null
    foreach ($lib in (Find-SteamLibraries)) {
        $candidate = Join-Path $lib "steamapps\common\Buckshot Roulette\Buckshot Roulette_windows"
        if (Test-Path (Join-Path $candidate "$ExeName.stock.bak")) { $found = $candidate; break }
        if (Test-Path (Join-Path $candidate $ExeName)) { $found = $candidate }
    }
    if ($found) { $GameDir = $found }
}

if ([string]::IsNullOrWhiteSpace($GameDir)) { Die "Could not find the game folder. Re-run with -GameDir." }

$Stock  = Join-Path $GameDir $ExeName
$Backup = "$Stock.stock.bak"

if (-not (Test-Path $Backup)) {
    Die "No backup found at $Backup - was the mod ever installed here?"
}

Say "Restoring original exe..."
Move-Item -Force -Path $Backup -Destination $Stock

$SteamBackup = Join-Path $GameDir "steam_api64.dll.stock.bak"
if (Test-Path $SteamBackup) {
    Say "Restoring original steam_api64.dll..."
    Move-Item -Force -Path $SteamBackup -Destination (Join-Path $GameDir "steam_api64.dll")
}
Say "Done. Original exe and Steam library restored."

$ModsDir = Join-Path $GameDir "mods"
if (Test-Path $ModsDir) {
    $items = Get-ChildItem $ModsDir -ErrorAction SilentlyContinue
    if (-not $items) { Remove-Item -Force $ModsDir }
}
