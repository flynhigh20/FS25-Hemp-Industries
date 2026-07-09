param(
    [switch]$Install,
    [switch]$CleanOldZips,
    [string]$ModsDir = "$env:USERPROFILE\Documents\My Games\FarmingSimulator2025\mods"
)

$ErrorActionPreference = "Stop"

function Find-RepoRoot {
    $scriptDir = Split-Path -Parent $PSCommandPath
    $current = Resolve-Path $scriptDir

    while ($null -ne $current) {
        $candidate = Join-Path $current "FS25_GreenHorizonIndustries\modDesc.xml"
        if (Test-Path $candidate) {
            return $current.Path
        }

        $parent = Split-Path -Parent $current
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $current.Path) {
            break
        }
        $current = Resolve-Path $parent
    }

    throw "Could not find repo root. Run this script from inside the FS25-Hemp-Industries repo."
}

function Get-ModVersion {
    param([string]$ModDescPath)

    [xml]$modDesc = Get-Content -Path $ModDescPath -Raw
    return $modDesc.modDesc.version.Trim()
}

function Test-ZipRoot {
    param([string]$ZipPath)

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
    try {
        $hasModDescAtRoot = $false
        foreach ($entry in $zip.Entries) {
            if ($entry.FullName -eq "modDesc.xml") {
                $hasModDescAtRoot = $true
                break
            }
        }
        return $hasModDescAtRoot
    }
    finally {
        $zip.Dispose()
    }
}

$repoRoot = Find-RepoRoot
$modFolder = Join-Path $repoRoot "FS25_GreenHorizonIndustries"
$modDescPath = Join-Path $modFolder "modDesc.xml"
$distDir = Join-Path $repoRoot "dist"
$zipPath = Join-Path $distDir "FS25_GreenHorizonIndustries.zip"
$version = Get-ModVersion -ModDescPath $modDescPath

Write-Host "Green Horizon Industries Windows Packager" -ForegroundColor Green
Write-Host "Repo: $repoRoot"
Write-Host "Mod folder: $modFolder"
Write-Host "Version: $version"

if (-not (Test-Path $modFolder)) {
    throw "Missing mod folder: $modFolder"
}

if (-not (Test-Path $modDescPath)) {
    throw "Missing modDesc.xml: $modDescPath"
}

if (Test-Path $distDir) {
    New-Item -ItemType Directory -Force -Path $distDir | Out-Null
} else {
    New-Item -ItemType Directory -Path $distDir | Out-Null
}

if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

# Important: zip the CONTENTS of FS25_GreenHorizonIndustries, not the parent folder.
$items = Get-ChildItem -Path $modFolder -Force
Compress-Archive -Path $items.FullName -DestinationPath $zipPath -CompressionLevel Optimal

if (-not (Test-ZipRoot -ZipPath $zipPath)) {
    throw "Bad zip root. modDesc.xml is not at the top of the zip. Do not use this zip."
}

Write-Host "Created: $zipPath" -ForegroundColor Cyan
Write-Host "Zip root check: PASS - modDesc.xml is at the top of the zip." -ForegroundColor Green

if ($Install) {
    New-Item -ItemType Directory -Force -Path $ModsDir | Out-Null

    if ($CleanOldZips) {
        $oldZipNames = @(
            "FS25_GreenHorizonIndustries.zip",
            "FS25_Hemp_Industries.zip"
        )

        foreach ($name in $oldZipNames) {
            $oldPath = Join-Path $ModsDir $name
            if (Test-Path $oldPath) {
                Remove-Item $oldPath -Force
                Write-Host "Removed old zip: $oldPath" -ForegroundColor Yellow
            }
        }
    }

    Copy-Item -Path $zipPath -Destination (Join-Path $ModsDir "FS25_GreenHorizonIndustries.zip") -Force
    Write-Host "Installed to: $ModsDir" -ForegroundColor Cyan
}

Write-Host "Done. In FS25, confirm the mod list shows version $version." -ForegroundColor Green
