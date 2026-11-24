[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$buildDir = Join-Path $repoRoot 'build'
$generatedIds = Join-Path $buildDir 'generated/resource_ids.h'
$iconsDir = Join-Path $repoRoot 'assets/icons'

function Test-CMake {
    $cmake = Get-Command cmake -ErrorAction SilentlyContinue
    if (-not $cmake) {
        Write-Host 'CMake est introuvable. Installez CMake 3.24+ et ajoutez-le au PATH.' -ForegroundColor Red
        return $false
    }

    $versionLine = (& cmake --version | Select-Object -First 1)
    if ($versionLine -notmatch 'cmake version (\d+)\.(\d+)') {
        Write-Host 'Impossible de déterminer la version de CMake.' -ForegroundColor Red
        return $false
    }
    $major = [int]$Matches[1]
    $minor = [int]$Matches[2]
    if (($major -lt 3) -or (($major -eq 3) -and ($minor -lt 24))) {
        Write-Host "CMake 3.24+ est requis. Version trouvée : $versionLine" -ForegroundColor Red
        return $false
    }
    return $true
}

function Show-IconIds {
    if (-not (Test-Path $generatedIds)) {
        Write-Host 'Les identifiants ne sont pas encore générés. Lancez une compilation d’abord.' -ForegroundColor Yellow
        return
    }
    $entries = Get-Content $generatedIds | Where-Object { $_ -match '^#define ICON_' }
    if (-not $entries) {
        Write-Host 'Aucune icône intégrée. Ajoutez des fichiers .ico dans assets/icons/ puis reconfigurez.' -ForegroundColor Yellow
        return
    }
    Write-Host "`nIdentifiants générés :"
    foreach ($entry in $entries) {
        if ($entry -match '^#define\s+(\S+)\s+(\d+)') {
            Write-Host ("  {0,-28} {1}" -f $Matches[1], $Matches[2])
        }
    }
}

function Invoke-Build {
    if (-not (Test-CMake)) { return }
    $architectures = @('x64', 'Win32', 'ARM64')
    Write-Host "Architecture : 1) x64  2) Win32  3) ARM64"
    $selection = Read-Host 'Choix [1]'
    if ([string]::IsNullOrWhiteSpace($selection)) { $selection = '1' }
    $architecture = switch ($selection) {
        '1' { 'x64' }
        '2' { 'Win32' }
        '3' { 'ARM64' }
        default { Write-Host 'Choix invalide.' -ForegroundColor Yellow; return }
    }

    if (-not (Get-Command cl.exe -ErrorAction SilentlyContinue)) {
        Write-Host 'cl.exe n’est pas dans le PATH. Ouvrez VS Code depuis Developer PowerShell for VS 2022.' -ForegroundColor Yellow
        Write-Host 'Le générateur Visual Studio peut toutefois trouver MSVC si Visual Studio Build Tools est installé.' -ForegroundColor Yellow
    }

    Push-Location $repoRoot
    try {
        & cmake -S . -B build -G 'Visual Studio 17 2022' -A $architecture
        if ($LASTEXITCODE -ne 0) { throw 'La configuration CMake a échoué.' }
        & cmake --build build --config Release
        if ($LASTEXITCODE -ne 0) { throw 'La compilation a échoué.' }
        Write-Host "`nDLL créée : $(Join-Path $buildDir 'bin/Release/AD-Icons.dll')" -ForegroundColor Green
        Show-IconIds
    }
    catch {
        Write-Host $_ -ForegroundColor Red
    }
    finally {
        Pop-Location
    }
}

if (-not $IsWindows -and $env:OS -ne 'Windows_NT') {
    Write-Host 'Ce projet nécessite Windows, Visual Studio C++ et le Windows SDK.' -ForegroundColor Red
    exit 1
}

while ($true) {
    Write-Host "`n=== DLL d’icônes AD ==="
    Write-Host '1) Configurer et compiler la DLL (Release)'
    Write-Host '2) Afficher les identifiants des icônes'
    Write-Host '3) Ouvrir le dossier des icônes'
    Write-Host '4) Quitter'
    $choice = Read-Host 'Sélection'
    switch ($choice) {
        '1' { Invoke-Build }
        '2' { Show-IconIds }
        '3' { Start-Process explorer.exe -ArgumentList $iconsDir }
        '4' { return }
        default { Write-Host 'Choix invalide.' -ForegroundColor Yellow }
    }
}
