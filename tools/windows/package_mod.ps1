param(
    [switch]$Install,
    [switch]$InstallLoose,
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
        foreach ($entry in $zip.Entries) {
            if ($entry.FullName -eq "modDesc.xml") {
                return $true
            }
        }
        return $false
    }
    finally {
        $zip.Dispose()
    }
}

function Test-ZipRequiredEntries {
    param(
        [string]$ZipPath,
        [string[]]$RequiredEntries
    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
    try {
        $entryNames = @{}
        foreach ($entry in $zip.Entries) {
            $entryNames[$entry.FullName.Replace("\", "/")] = $true
        }

        $missing = @()
        foreach ($required in $RequiredEntries) {
            if (-not $entryNames.ContainsKey($required)) {
                $missing += $required
            }
        }

        if ($missing.Count -gt 0) {
            throw "Package is missing required active file(s): $($missing -join ', ')"
        }

        foreach ($required in $RequiredEntries) {
            Write-Host "Zip contains required file: $required" -ForegroundColor Green
        }
    }
    finally {
        $zip.Dispose()
    }
}

function Copy-IconFromZip {
    param(
        [string]$ZipPath,
        [string]$DestinationPath
    )

    if (-not (Test-Path $ZipPath)) {
        return $false
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
    try {
        foreach ($entry in $zip.Entries) {
            if ($entry.FullName -eq "icon_mod.dds") {
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $DestinationPath, $true)
                return $true
            }
        }
        return $false
    }
    finally {
        $zip.Dispose()
    }
}

function Restore-ExistingIcon {
    param(
        [string]$ModFolder,
        [string]$ModsDir
    )

    $iconPath = Join-Path $ModFolder "icon_mod.dds"
    if (Test-Path $iconPath) {
        Write-Host "Icon exists: icon_mod.dds" -ForegroundColor Green
        return
    }

    $looseIcon = Join-Path $ModsDir "FS25_GreenHorizonIndustries\icon_mod.dds"
    if (Test-Path $looseIcon) {
        Copy-Item -Path $looseIcon -Destination $iconPath -Force
        Write-Host "Recovered icon_mod.dds from installed loose mod folder." -ForegroundColor Green
        return
    }

    $zipIconSource = Join-Path $ModsDir "FS25_GreenHorizonIndustries.zip"
    if (Copy-IconFromZip -ZipPath $zipIconSource -DestinationPath $iconPath) {
        Write-Host "Recovered icon_mod.dds from installed mod zip." -ForegroundColor Green
        return
    }

    Write-Host "WARN: icon_mod.dds is missing. Put your known-good icon_mod.dds into FS25_GreenHorizonIndustries once." -ForegroundColor Yellow
}

function Remove-OldModInstall {
    param(
        [string]$ModsDir,
        [string]$Name
    )

    $target = Join-Path $ModsDir $Name
    if (Test-Path $target) {
        $item = Get-Item $target
        if ($item.PSIsContainer) {
            Remove-Item $target -Recurse -Force
            Write-Host "Removed old loose mod folder: $target" -ForegroundColor Yellow
        }
        else {
            Remove-Item $target -Force
            Write-Host "Removed old mod file: $target" -ForegroundColor Yellow
        }
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

Restore-ExistingIcon -ModFolder $modFolder -ModsDir $ModsDir

New-Item -ItemType Directory -Force -Path $distDir | Out-Null

if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

# Do not package helper backup files. FS25 should see the real icon_mod.dds only.
$items = Get-ChildItem -Path $modFolder -Force | Where-Object { $_.Name -ne "icon_mod.dds.b64" }
Compress-Archive -Path $items.FullName -DestinationPath $zipPath -CompressionLevel Optimal

if (-not (Test-ZipRoot -ZipPath $zipPath)) {
    throw "Bad zip root. modDesc.xml is not at the top of the zip. Do not use this zip."
}

Test-ZipRequiredEntries -ZipPath $zipPath -RequiredEntries @(
    "modDesc.xml",
    "xml/fillTypes.xml",
    "placeables/greenhouses/hempGreenhouse.xml"
)

Write-Host "Created: $zipPath" -ForegroundColor Cyan
Write-Host "Zip root check: PASS - modDesc.xml is at the top of the zip." -ForegroundColor Green

if ($CleanOldZips) {
    New-Item -ItemType Directory -Force -Path $ModsDir | Out-Null
    $oldNames = @(
        "FS25_GreenHorizonIndustries.zip",
        "FS25_GreenHorizonIndustries",
        "FS25_Hemp_Industries.zip",
        "FS25_Hemp_Industries"
    )

    foreach ($name in $oldNames) {
        Remove-OldModInstall -ModsDir $ModsDir -Name $name
    }
}

if ($Install) {
    New-Item -ItemType Directory -Force -Path $ModsDir | Out-Null
    Copy-Item -Path $zipPath -Destination (Join-Path $ModsDir "FS25_GreenHorizonIndustries.zip") -Force
    Write-Host "Installed zip to: $ModsDir" -ForegroundColor Cyan
}

if ($InstallLoose) {
    New-Item -ItemType Directory -Force -Path $ModsDir | Out-Null
    $looseTarget = Join-Path $ModsDir "FS25_GreenHorizonIndustries"
    if (Test-Path $looseTarget) {
        Remove-Item $looseTarget -Recurse -Force
    }
    Copy-Item -Path $modFolder -Destination $ModsDir -Recurse -Force
    Write-Host "Installed loose folder to: $looseTarget" -ForegroundColor Cyan
    Write-Host "Use the loose folder for GIANTS Icon Generator testing." -ForegroundColor Cyan
}

Write-Host "Done. In FS25, confirm the mod list shows version $version." -ForegroundColor Green
