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
        if (Test-Path (Join-Path $current "FS25_GreenHorizonIndustries\modDesc.xml")) {
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

function Remove-OldModInstall {
    param(
        [string]$Directory,
        [string]$Name
    )

    $target = Join-Path $Directory $Name
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

function Assert-RequiredFiles {
    param(
        [string]$ModFolder,
        [string[]]$RelativePaths
    )

    foreach ($relativePath in $RelativePaths) {
        $fullPath = Join-Path $ModFolder ($relativePath.Replace("/", "\"))
        if (-not (Test-Path $fullPath)) {
            throw "Missing required mod file: $relativePath"
        }
        Write-Host "Found required file: $relativePath" -ForegroundColor Green
    }
}

function Assert-ZipEntries {
    param(
        [string]$ZipPath,
        [string[]]$RelativePaths
    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
    try {
        $entries = @{}
        foreach ($entry in $zip.Entries) {
            $entries[$entry.FullName.Replace("\", "/")] = $true
        }

        foreach ($relativePath in $RelativePaths) {
            if (-not $entries.ContainsKey($relativePath)) {
                throw "Package is missing required file: $relativePath"
            }
            Write-Host "Zip contains required file: $relativePath" -ForegroundColor Green
        }
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

[xml]$modDesc = Get-Content -Path $modDescPath -Raw
$version = $modDesc.modDesc.version.Trim()

$requiredEntries = @(
    "modDesc.xml",
    "icon_mod.dds",
    "xml/fillTypes.xml",
    "xml/fruitTypes.xml",
    "xml/growth/hempGrowth.xml",
    "foliage/hemp/hempFoliagePlan.xml",
    "foliage/hemp/hempFieldIntegrationPlan.xml",
    "placeables/greenhouses/hempGreenhouse.xml",
    "placeables/greenhouses/i3d/greenHorizonHempGreenhouse.i3d",
    "placeables/greenhouses/i3d/greenHorizonHempGreenhouse.i3d.shapes",
    "placeables/greenhouses/textures/greenhouse_glass_diffuse.png",
    "placeables/greenhouses/textures/greenhouse_frame_diffuse.png",
    "placeables/greenhouses/textures/greenhouse_concrete_diffuse.png",
    "placeables/greenhouses/textures/greenhouse_soil_diffuse.png",
    "placeables/greenhouses/textures/greenhouse_hemp_leaf_diffuse.png",
    "placeables/greenhouses/textures/greenhouse_stem_diffuse.png",
    "placeables/greenhouses/textures/greenhouse_water_tank_diffuse.png",
    "placeables/greenhouses/textures/greenhouse_rubber_diffuse.png",
    "placeables/greenhouses/textures/greenhouse_wire_diffuse.png",
    "placeables/greenhouses/textures/greenhouse_light_diffuse.png"
)

Write-Host "Green Horizon Industries Windows Packager" -ForegroundColor Green
Write-Host "Repo: $repoRoot"
Write-Host "Version: $version"

Assert-RequiredFiles -ModFolder $modFolder -RelativePaths $requiredEntries

New-Item -ItemType Directory -Force -Path $distDir | Out-Null
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

# Package the contents of the mod folder so modDesc.xml stays at the zip root.
$items = Get-ChildItem -Path $modFolder -Force |
    Where-Object { $_.Name -ne "icon_mod.dds.b64" -and $_.Name -notlike "*.bak" }

Compress-Archive -Path $items.FullName -DestinationPath $zipPath -CompressionLevel Optimal
Assert-ZipEntries -ZipPath $zipPath -RelativePaths $requiredEntries

Write-Host "Created: $zipPath" -ForegroundColor Cyan
Write-Host "Zip root check: PASS" -ForegroundColor Green

if ($CleanOldZips) {
    New-Item -ItemType Directory -Force -Path $ModsDir | Out-Null
    foreach ($oldName in @(
        "FS25_GreenHorizonIndustries.zip",
        "FS25_GreenHorizonIndustries",
        "FS25_Hemp_Industries.zip",
        "FS25_Hemp_Industries"
    )) {
        Remove-OldModInstall -Directory $ModsDir -Name $oldName
    }
}

if ($Install) {
    New-Item -ItemType Directory -Force -Path $ModsDir | Out-Null

    # A loose folder can override or conflict with the zip. Always remove it.
    Remove-OldModInstall -Directory $ModsDir -Name "FS25_GreenHorizonIndustries"
    Remove-OldModInstall -Directory $ModsDir -Name "FS25_GreenHorizonIndustries.zip"

    Copy-Item -Path $zipPath -Destination (Join-Path $ModsDir "FS25_GreenHorizonIndustries.zip") -Force
    Write-Host "Installed zip to: $ModsDir" -ForegroundColor Cyan
}

if ($InstallLoose) {
    New-Item -ItemType Directory -Force -Path $ModsDir | Out-Null
    Remove-OldModInstall -Directory $ModsDir -Name "FS25_GreenHorizonIndustries.zip"
    Remove-OldModInstall -Directory $ModsDir -Name "FS25_GreenHorizonIndustries"

    Copy-Item -Path $modFolder -Destination $ModsDir -Recurse -Force
    Write-Host "Installed loose folder to: $ModsDir\FS25_GreenHorizonIndustries" -ForegroundColor Cyan
}

Write-Host "Done. In FS25, confirm the mod list shows version $version." -ForegroundColor Green
