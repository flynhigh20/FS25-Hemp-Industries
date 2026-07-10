param(
    [string]$ModsDir = "$env:USERPROFILE\Documents\My Games\FarmingSimulator2025\mods"
)

$ErrorActionPreference = "Stop"

function Find-RepoRoot {
    $current = Resolve-Path (Split-Path -Parent $PSCommandPath)
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

    throw "Could not find repository root."
}

function Mark([bool]$Complete) {
    if ($Complete) { return "READY" }
    return "MISSING"
}

function Count-Existing {
    param([string]$Root, [string[]]$RelativePaths)

    $count = 0
    foreach ($relativePath in $RelativePaths) {
        if (Test-Path (Join-Path $Root ($relativePath.Replace("/", "\")))) {
            $count += 1
        }
    }
    return $count
}

$root = Find-RepoRoot
$modFolder = Join-Path $root "FS25_GreenHorizonIndustries"
[xml]$modDesc = Get-Content -Path (Join-Path $modFolder "modDesc.xml") -Raw
$version = $modDesc.modDesc.version.Trim()

$greenhouseBlend = Join-Path $root "assets\blender\green_horizon_hemp_greenhouse.blend"
$i3d = Join-Path $modFolder "placeables\greenhouses\i3d\greenHorizonHempGreenhouse.i3d"
$shapes = "$i3d.shapes"
$zip = Join-Path $root "dist\FS25_GreenHorizonIndustries.zip"
$installedZip = Join-Path $ModsDir "FS25_GreenHorizonIndustries.zip"

$greenhouseGenerated = Test-Path $greenhouseBlend
$i3dExists = Test-Path $i3d
$shapesExists = Test-Path $shapes
$realExport = $false

if ($i3dExists) {
    $raw = Get-Content -Path $i3d -Raw
    $realExport = $raw -notmatch "placeholder" -and $raw -match 'name="greenHorizonHempGreenhouse"'
}

$foliageAssets = @(
    "assets/blender/green_horizon_hemp_foliage.blend",
    "FS25_GreenHorizonIndustries/foliage/hemp/textures/hempFoliage_diffuse.png",
    "FS25_GreenHorizonIndustries/foliage/hemp/textures/hempFoliage_normal.png",
    "FS25_GreenHorizonIndustries/foliage/hemp/textures/hempFoliage_distance_diffuse.png",
    "FS25_GreenHorizonIndustries/foliage/hemp/textures/hempFoliage_distance_normal.png"
)

$iconAssets = @(
    "FS25_GreenHorizonIndustries/ui/icons/fillType_hemp.png",
    "FS25_GreenHorizonIndustries/ui/icons/fillType_hempSeed.png",
    "FS25_GreenHorizonIndustries/ui/icons/fillType_hempBiomass.png",
    "FS25_GreenHorizonIndustries/ui/icons/fillType_hempFiber.png",
    "FS25_GreenHorizonIndustries/ui/icons/fillType_hempFlower.png",
    "FS25_GreenHorizonIndustries/ui/icons/fillType_hempOil.png",
    "FS25_GreenHorizonIndustries/ui/icons/crop_hemp.png",
    "FS25_GreenHorizonIndustries/ui/icons/calendar_hemp.png"
)

$cutterAssets = @(
    "assets/blender/green_horizon_hemp_cutter_effects.blend",
    "FS25_GreenHorizonIndustries/foliage/hemp/effects/textures/hemp_chaff_diffuse.png",
    "FS25_GreenHorizonIndustries/foliage/hemp/effects/textures/hemp_stem_shard_diffuse.png",
    "FS25_GreenHorizonIndustries/foliage/hemp/effects/textures/hemp_leaf_fragment_diffuse.png",
    "FS25_GreenHorizonIndustries/foliage/hemp/effects/textures/hemp_dust_diffuse.png"
)

$palletAssets = @(
    "assets/blender/green_horizon_product_pallets.blend",
    "FS25_GreenHorizonIndustries/pallets/textures/pallet_wood_diffuse.png",
    "FS25_GreenHorizonIndustries/pallets/textures/pallet_hemp_diffuse.png",
    "FS25_GreenHorizonIndustries/pallets/textures/pallet_seed_diffuse.png",
    "FS25_GreenHorizonIndustries/pallets/textures/pallet_biomass_diffuse.png",
    "FS25_GreenHorizonIndustries/pallets/textures/pallet_fiber_diffuse.png",
    "FS25_GreenHorizonIndustries/pallets/textures/pallet_flower_diffuse.png",
    "FS25_GreenHorizonIndustries/pallets/textures/pallet_oil_diffuse.png"
)

$foliageCount = Count-Existing -Root $root -RelativePaths $foliageAssets
$iconCount = Count-Existing -Root $root -RelativePaths $iconAssets
$cutterCount = Count-Existing -Root $root -RelativePaths $cutterAssets
$palletCount = Count-Existing -Root $root -RelativePaths $palletAssets

Write-Host "Green Horizon Industries - Project Status" -ForegroundColor Cyan
Write-Host "Version: $version"
Write-Host "Repo:    $root"
Write-Host ""

Write-Host "ACTIVE GREENHOUSE FLOW" -ForegroundColor Cyan
Write-Host ("  Generated Blender model : {0}" -f (Mark $greenhouseGenerated))
Write-Host ("  Real exported i3d       : {0}" -f (Mark $realExport))
Write-Host ("  Exported shapes file    : {0}" -f (Mark $shapesExists))
Write-Host ("  Packaged ZIP            : {0}" -f (Mark (Test-Path $zip)))
Write-Host ("  Installed ZIP           : {0}" -f (Mark (Test-Path $installedZip)))
Write-Host ""

Write-Host "INACTIVE EXPANSION ASSETS" -ForegroundColor Cyan
Write-Host "  Foliage:       $foliageCount / $($foliageAssets.Count)"
Write-Host "  Icons:         $iconCount / $($iconAssets.Count)"
Write-Host "  Cutter effects:$cutterCount / $($cutterAssets.Count)"
Write-Host "  Pallet sources:$palletCount / $($palletAssets.Count)"
Write-Host ""

Write-Host "NEXT ACTION" -ForegroundColor Yellow
if (-not $greenhouseGenerated) {
    Write-Host "Run menu option 9 to generate the greenhouse, or option 12 to generate everything."
}
elif (-not $realExport -or -not $shapesExists) {
    Write-Host "Open the generated greenhouse blend and export greenHorizonHempGreenhouse to the mod i3d folder."
    Write-Host "Use relative paths Yes and game paths No, then save it in GIANTS Editor."
}
elif (-not (Test-Path $zip)) {
    Write-Host "Run menu option 13 to validate the export, then option 3 to package and install."
}
elif (-not (Test-Path $installedZip)) {
    Write-Host "Run menu option 3 to install the clean ZIP into the FS25 mods folder."
}
else {
    $sourceTime = (Get-Item $i3d).LastWriteTimeUtc
    $installedTime = (Get-Item $installedZip).LastWriteTimeUtc
    if ($sourceTime -gt $installedTime) {
        Write-Host "The exported i3d is newer than the installed ZIP. Run menu option 3 again."
    }
    else {
        Write-Host "Start FS25, test the greenhouse, then run menu option 4 to check the log."
    }
}

Write-Host ""
Write-Host "Field, icon, cutter, and pallet assets stay inactive even after generation." -ForegroundColor DarkGray
