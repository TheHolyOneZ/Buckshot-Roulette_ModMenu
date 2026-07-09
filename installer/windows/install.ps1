#Requires -Version 5.1
param(
    [string]$GameDir = ""
)

$ErrorActionPreference = "Stop"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path

$Patch     = Join-Path $Here "br_2206_win.patch.zst"
$ZstdExe   = Join-Path $Here "zstd.exe"
$SteamDll  = Join-Path $Here "steam_api64.dll"
$ExeName   = "Buckshot Roulette.exe"
$TargetVersion = "Steam v2.2.0.6"
$StockSha  = "DF2F8A31BD469438A1A29F831945CCEA7B26963AB735F73B32936792207B1663"
$ModdedSha = "2D86FE1EB5B652DE938800EED68262216774571AC8BDDF9629488F1B416FDDB5"

function Say($msg)  { Write-Host "[modmenu] $msg" -ForegroundColor Cyan }
function Err($msg)  { Write-Host "[error] $msg" -ForegroundColor Red }
function Die($msg)  { Err $msg; exit 1 }

if (-not (Test-Path $Patch))    { Die "Missing patch file next to this script: $Patch" }
if (-not (Test-Path $ZstdExe))  { Die "Missing zstd.exe next to this script: $ZstdExe" }
if (-not (Test-Path $SteamDll)) { Die "Missing steam_api64.dll next to this script: $SteamDll" }

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
        if (Test-Path (Join-Path $candidate $ExeName)) { $found = $candidate; break }
    }
    if ($found) { $GameDir = $found }
}

if ([string]::IsNullOrWhiteSpace($GameDir) -or -not (Test-Path (Join-Path $GameDir $ExeName))) {
    Die "Could not find '$ExeName'. Re-run with the game folder:`n        .\install.ps1 -GameDir `"D:\path\to\Buckshot Roulette_windows`""
}

$Stock = Join-Path $GameDir $ExeName
Say "Game folder: $GameDir"

Say "Verifying game version ($TargetVersion)..."
$CurSha = (Get-FileHash -Path $Stock -Algorithm SHA256).Hash

if ($CurSha -eq $ModdedSha) {
    Say "This exe is ALREADY patched. Making sure the Steam library is in place."
} elseif ($CurSha -ne $StockSha) {
    Die @"
This exe does not match $TargetVersion.
        Expected stock sha256: $StockSha
        Found:                 $CurSha
        The game was probably updated. Do NOT force it - a mismatched patch
        would corrupt the exe. A version-matched patch is needed instead.
"@
}

$Backup = "$Stock.stock.bak"
if ($CurSha -eq $StockSha) {
    if (-not (Test-Path $Backup)) {
        Say "Backing up original exe -> $(Split-Path -Leaf $Backup)"
        Copy-Item -Path $Stock -Destination $Backup -Force
    }
    Say "Applying patch (rebuilding modded exe locally)..."
    $Tmp = "$Stock.tmp"
    & $ZstdExe -q -d --long=31 --patch-from="$Backup" "$Patch" -o "$Tmp" -f
    if ($LASTEXITCODE -ne 0) { Die "zstd failed to apply the patch." }

    $OutSha = (Get-FileHash -Path $Tmp -Algorithm SHA256).Hash
    if ($OutSha -ne $ModdedSha) {
        Remove-Item -Force $Tmp
        Die "Patched exe hash mismatch - aborting, original untouched."
    }
    Move-Item -Force -Path $Tmp -Destination $Stock
    Say "Patch applied and verified."
}

$SteamTarget = Join-Path $GameDir "steam_api64.dll"
$SteamBackup = Join-Path $GameDir "steam_api64.dll.stock.bak"
if ((Test-Path $SteamTarget) -and -not (Test-Path $SteamBackup)) {
    Say "Backing up stock steam_api64.dll -> steam_api64.dll.stock.bak"
    Copy-Item -Path $SteamTarget -Destination $SteamBackup -Force
}
Say "Installing matching Steam library (steam_api64.dll)..."
Copy-Item -Path $SteamDll -Destination $SteamTarget -Force

$ModsDir = Join-Path $GameDir "mods"
if (-not (Test-Path $ModsDir)) { New-Item -ItemType Directory -Path $ModsDir | Out-Null }
Say "Ready. (mods\ folder created for any extra mods you want to add.)"

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
Write-Host "Launch the game normally (Steam Play button, or run the exe)."
Write-Host "The small mod menu appears top-left. Click the toggles or use the hotkeys:"
Write-Host "   [Right Shift] show / hide the menu"
Write-Host "   F1  God Mode      F4  Instant-Kill      F3  Shell Order ESP"
Write-Host "   F5  Multiplayer Mode   (for MP cheats you must HOST the lobby - see README.txt)"
Write-Host ""
Write-Host "To uninstall: run .\uninstall.ps1  (restores your original exe and Steam library)"
