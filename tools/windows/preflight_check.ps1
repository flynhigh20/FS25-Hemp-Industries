param(
    [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"
$expectedVersion = "0.2.18.0"
$failures = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

function Find-RepoRoot {
    if (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
        return (Resolve-Path $RepoRoot).Path
    }

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

function Pass([string]$Message) {
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Warn([string]$Message) {
    $warnings.Add($Message) | Out-Null
    Write-Host "WARN: $Message" -ForegroundColor Yellow
}

function Fail([string]$Message) {
    $failures.Add($Message) | Out-Null
    Write-Host "FAIL: $Message" -ForegroundColor Red
}

function Read-Xml([string]$Path) {
    try {
        return [xml](Get-Content -Path $Path -Raw)
    }
    catch {
        Fail "XML parse failed: $Path -- $($_.Exception.Message)"
        return $null
    }
}

function Check-OptionalSet {
    param(
        [string]$BaseFolder,
        [string[]]$RelativePaths,
        [string]$Description,
        [string]$RunHint
    )

    $found = 0
    foreach ($relativePath in $RelativePaths) {
        $fullPath = Join-Path $BaseFolder ($relativePath.Replace("/", "\"))
        if (Test-Path $fullPath) {
            $found += 1
            Pass "$Description exists: $relativePath"
        }
    }

    if ($found -eq 0) {
        Warn "$Description files are not generated yet; $RunHint"
    }
    elseif ($found -ne $RelativePaths.Count) {
        Fail "Only $found of $($RelativePaths.Count) $Description files exist."
    }
}

$root = Find-RepoRoot
$modFolder = Join-Path $root "FS25_GreenHorizonIndustries"

$requiredFiles = @(
    "modDesc.xml",
    "icon_mod.dds",
    "xml/fillTypes.xml",
    "xml/fruitTypes.xml",
    "xml/growth/hempGrowth.xml",
    "xml/productions/hempProcessingRecipes.xml",
    "foliage/hemp/hempFoliagePlan.xml",
    "foliage/hemp/hempFieldIntegrationPlan.xml",
    "foliage/hemp/hempMapRegistrationDraft.xml",
    "foliage/hemp/hempCutterEffectsPlan.xml",
    "ui/hempIconManifest.xml",
    "pallets/xml/hempPallet.xml",
    "pallets/xml/seedPallet.xml",
    "pallets/xml/biomassPallet.xml",
    "pallets/xml/fiberPallet.xml",
    "pallets/xml/flowerPallet.xml",
    "pallets/xml/oilPallet.xml",
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

$requiredToolFiles = @(
    "tools/blender/create_green_horizon_greenhouse.py",
    "tools/blender/create_hemp_foliage.py",
    "tools/blender/create_hemp_crop_icons.py",
    "tools/blender/create_hemp_cutter_effects.py",
    "tools/blender/create_green_horizon_pallets.py",
    "tools/windows/generate_project_assets.ps1",
    "tools/windows/validate_greenhouse_export.ps1",
    "tools/windows/check_hemp_field_foundation.ps1",
    "tools/windows/show_project_status.ps1"
)

Write-Host "Green Horizon Industries - Preflight" -ForegroundColor Cyan
Write-Host "Expected version: $expectedVersion"
Write-Host ""

foreach ($relativePath in $requiredFiles) {
    $fullPath = Join-Path $modFolder ($relativePath.Replace("/", "\"))
    if (Test-Path $fullPath) { Pass "Found $relativePath" } else { Fail "Missing required file: $relativePath" }
}

foreach ($relativePath in $requiredToolFiles) {
    $fullPath = Join-Path $root ($relativePath.Replace("/", "\"))
    if (Test-Path $fullPath) { Pass "Found $relativePath" } else { Fail "Missing tool file: $relativePath" }
}

Check-OptionalSet -BaseFolder $modFolder -Description "Generated foliage texture" -RunHint "run menu option 10 or 12 later." -RelativePaths @(
    "foliage/hemp/textures/hempFoliage_diffuse.png",
    "foliage/hemp/textures/hempFoliage_normal.png",
    "foliage/hemp/textures/hempFoliage_distance_diffuse.png",
    "foliage/hemp/textures/hempFoliage_distance_normal.png"
)

Check-OptionalSet -BaseFolder $modFolder -Description "Generated crop icon" -RunHint "run menu option 10 or 12 later." -RelativePaths @(
    "ui/icons/fillType_hemp.png",
    "ui/icons/fillType_hempSeed.png",
    "ui/icons/fillType_hempBiomass.png",
    "ui/icons/fillType_hempFiber.png",
    "ui/icons/fillType_hempFlower.png",
    "ui/icons/fillType_hempOil.png",
    "ui/icons/crop_hemp.png",
    "ui/icons/calendar_hemp.png"
)

Check-OptionalSet -BaseFolder $modFolder -Description "Generated cutter-effect texture" -RunHint "run menu option 10 or 12 later." -RelativePaths @(
    "foliage/hemp/effects/textures/hemp_chaff_diffuse.png",
    "foliage/hemp/effects/textures/hemp_stem_shard_diffuse.png",
    "foliage/hemp/effects/textures/hemp_leaf_fragment_diffuse.png",
    "foliage/hemp/effects/textures/hemp_dust_diffuse.png"
)

Check-OptionalSet -BaseFolder $modFolder -Description "Generated pallet texture" -RunHint "run menu option 11 or 12 later." -RelativePaths @(
    "pallets/textures/pallet_wood_diffuse.png",
    "pallets/textures/pallet_dark_wood_diffuse.png",
    "pallets/textures/pallet_wrap_diffuse.png",
    "pallets/textures/pallet_label_diffuse.png",
    "pallets/textures/pallet_hemp_diffuse.png",
    "pallets/textures/pallet_seed_diffuse.png",
    "pallets/textures/pallet_biomass_diffuse.png",
    "pallets/textures/pallet_fiber_diffuse.png",
    "pallets/textures/pallet_flower_diffuse.png",
    "pallets/textures/pallet_oil_diffuse.png"
)

$modDesc = Read-Xml (Join-Path $modFolder "modDesc.xml")
$greenhouse = Read-Xml (Join-Path $modFolder "placeables\greenhouses\hempGreenhouse.xml")
$fillTypes = Read-Xml (Join-Path $modFolder "xml\fillTypes.xml")
$processing = Read-Xml (Join-Path $modFolder "xml\productions\hempProcessingRecipes.xml")
$iconManifest = Read-Xml (Join-Path $modFolder "ui\hempIconManifest.xml")
$cutterPlan = Read-Xml (Join-Path $modFolder "foliage\hemp\hempCutterEffectsPlan.xml")
$mapDraft = Read-Xml (Join-Path $modFolder "foliage\hemp\hempMapRegistrationDraft.xml")

if ($null -ne $modDesc) {
    if ($modDesc.modDesc.descVersion -eq "91") { Pass "modDesc descVersion is 91" } else { Warn "modDesc descVersion is $($modDesc.modDesc.descVersion)" }
    if ($modDesc.modDesc.version -eq $expectedVersion) { Pass "mod version is $expectedVersion" } else { Fail "mod version is $($modDesc.modDesc.version), expected $expectedVersion" }
    if ($modDesc.modDesc.iconFilename -eq "icon_mod.dds") { Pass "mod icon points to icon_mod.dds" } else { Fail "mod iconFilename is not icon_mod.dds" }
    if ($null -eq $modDesc.modDesc.fruitTypes) { Pass "field fruit type remains safely inactive" } else { Fail "fruitTypes was activated too early" }

    $activeStoreItem = $modDesc.modDesc.storeItems.storeItem.xmlFilename
    if ($activeStoreItem -eq "placeables/greenhouses/hempGreenhouse.xml") { Pass "greenhouse store item is active" } else { Fail "greenhouse store item path is incorrect" }
}

$requiredFillTypes = @("HEMP", "GHI_HEMP_SEED", "GHI_HEMP_BIOMASS", "GHI_HEMP_FIBER", "GHI_HEMP_FLOWER", "GHI_HEMP_OIL")
if ($null -ne $fillTypes) {
    $fillNames = @($fillTypes.map.fillTypes.fillType | ForEach-Object { $_.name })
    foreach ($fillName in $requiredFillTypes) {
        if ($fillNames -contains $fillName) { Pass "fill type registered: $fillName" } else { Fail "missing fill type: $fillName" }
    }
}

if ($null -ne $iconManifest) {
    $icons = @($iconManifest.greenHorizonIconManifest.icons.icon)
    foreach ($fillName in $requiredFillTypes) {
        if (@($icons | Where-Object { $_.id -eq $fillName }).Count -eq 1) { Pass "icon manifest includes $fillName" } else { Fail "icon manifest missing or duplicates $fillName" }
    }
    if (@($icons | Where-Object { $_.linked -eq "true" }).Count -eq 0) { Pass "no icons are linked early" } else { Fail "one or more icons are linked before verification" }
}

if ($null -ne $cutterPlan) {
    $route = @($cutterPlan.greenHorizonCutterEffects.cropStateRouting.route | Where-Object { $_.growthState -eq "7" }) | Select-Object -First 1
    if ($null -ne $route -and $route.cutterAllowed -eq "true" -and $route.outputFillType -eq "HEMP" -and $route.resultingState -eq "9") {
        Pass "cutter plan routes mature HEMP to cut state 9"
    }
    else {
        Fail "cutter plan mature-state route is incorrect"
    }
}

if ($null -ne $mapDraft) {
    $contract = $mapDraft.greenHorizonMapRegistration.stateContract
    if ($contract.numStateChannels -eq "4" -and $contract.numGrowthStates -eq "7" -and $contract.harvestReadyState -eq "7" -and $contract.witheredState -eq "8" -and $contract.cutState -eq "9") {
        Pass "map registration state contract is synchronized"
    }
    else {
        Fail "map registration state contract is inconsistent"
    }
}

if ($null -ne $processing) {
    $recipes = @($processing.greenHorizonIndustries.productionRecipes.recipe)
    if ($recipes.Count -eq 4) { Pass "processing plan has four recipes" } else { Fail "processing plan has $($recipes.Count) recipes instead of four" }
}

$palletSpecs = @(
    @{ File = "hempPallet.xml"; FillType = "HEMP" },
    @{ File = "seedPallet.xml"; FillType = "GHI_HEMP_SEED" },
    @{ File = "biomassPallet.xml"; FillType = "GHI_HEMP_BIOMASS" },
    @{ File = "fiberPallet.xml"; FillType = "GHI_HEMP_FIBER" },
    @{ File = "flowerPallet.xml"; FillType = "GHI_HEMP_FLOWER" },
    @{ File = "oilPallet.xml"; FillType = "GHI_HEMP_OIL" }
)

foreach ($spec in $palletSpecs) {
    $xml = Read-Xml (Join-Path $modFolder ("pallets\xml\" + $spec.File))
    if ($null -eq $xml) { continue }
    $fillUnit = $xml.vehicle.fillUnit.fillUnitConfigurations.fillUnitConfiguration.fillUnits.fillUnit
    if ($xml.vehicle.type -eq "pallet" -and $fillUnit.fillTypes -eq $spec.FillType) {
        Pass "$($spec.File) is configured for $($spec.FillType)"
    }
    else {
        Fail "$($spec.File) pallet configuration is incorrect"
    }
}

if ($null -ne $greenhouse) {
    if ($greenhouse.placeable.type -eq "greenhouse") { Pass "placeable type is greenhouse" } else { Fail "placeable type is not greenhouse" }
    if ($greenhouse.placeable.base.filename -eq "placeables/greenhouses/i3d/greenHorizonHempGreenhouse.i3d") { Pass "greenhouse XML points to final i3d path" } else { Fail "greenhouse XML i3d path is incorrect" }
}

$fieldCheck = Join-Path $root "tools\windows\check_hemp_field_foundation.ps1"
if (Test-Path $fieldCheck) {
    Write-Host ""
    Write-Host "Running field hemp cross-file validator..." -ForegroundColor Cyan
    & $fieldCheck -RepoRoot $root
    if ($LASTEXITCODE -ne 0) { Fail "Field hemp foundation validator failed" } else { Pass "Field hemp foundation validator passed" }
}

$exportCheck = Join-Path $root "tools\windows\validate_greenhouse_export.ps1"
$i3dPath = Join-Path $modFolder "placeables\greenhouses\i3d\greenHorizonHempGreenhouse.i3d"
$shapesPath = "$i3dPath.shapes"
if ((Test-Path $exportCheck) -and (Test-Path $i3dPath) -and (Test-Path $shapesPath)) {
    Write-Host ""
    Write-Host "Running strict greenhouse export validator..." -ForegroundColor Cyan
    & $exportCheck -RepoRoot $root
    if ($LASTEXITCODE -ne 0) { Fail "Greenhouse export validator failed" } else { Pass "Greenhouse export validator passed" }
}

Write-Host ""
Write-Host "Preflight summary" -ForegroundColor Cyan
Write-Host "Failures: $($failures.Count)"
Write-Host "Warnings: $($warnings.Count)"

if ($failures.Count -gt 0) {
    exit 1
}

Write-Host "Preflight passed." -ForegroundColor Green
exit 0
