param(
    [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"
$expectedVersion = "0.2.17.0"
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

function Test-OptionalSet {
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
    "tools/blender/create_green_horizon_pallets.py"
)

$optionalFoliageTextures = @(
    "foliage/hemp/textures/hempFoliage_diffuse.png",
    "foliage/hemp/textures/hempFoliage_normal.png",
    "foliage/hemp/textures/hempFoliage_distance_diffuse.png",
    "foliage/hemp/textures/hempFoliage_distance_normal.png"
)

$optionalPalletTextures = @(
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

Write-Host "Green Horizon Industries - Preflight" -ForegroundColor Cyan
Write-Host "Expected version: $expectedVersion"
Write-Host ""

foreach ($relativePath in $requiredFiles) {
    $fullPath = Join-Path $modFolder ($relativePath.Replace("/", "\"))
    if (Test-Path $fullPath) {
        Pass "Found $relativePath"
    }
    else {
        Fail "Missing required file: $relativePath"
    }
}

foreach ($relativePath in $requiredToolFiles) {
    $fullPath = Join-Path $root ($relativePath.Replace("/", "\"))
    if (Test-Path $fullPath) {
        Pass "Found $relativePath"
    }
    else {
        Fail "Missing tool file: $relativePath"
    }
}

Test-OptionalSet -BaseFolder $modFolder -RelativePaths $optionalFoliageTextures -Description "Generated foliage texture" -RunHint "run tools/blender/create_hemp_foliage.py later."
Test-OptionalSet -BaseFolder $modFolder -RelativePaths $optionalPalletTextures -Description "Generated pallet texture" -RunHint "run tools/blender/create_green_horizon_pallets.py later."

$modDescPath = Join-Path $modFolder "modDesc.xml"
$greenhousePath = Join-Path $modFolder "placeables\greenhouses\hempGreenhouse.xml"
$fillTypesPath = Join-Path $modFolder "xml\fillTypes.xml"
$fruitTypesPath = Join-Path $modFolder "xml\fruitTypes.xml"
$growthPath = Join-Path $modFolder "xml\growth\hempGrowth.xml"
$foliagePlanPath = Join-Path $modFolder "foliage\hemp\hempFoliagePlan.xml"
$integrationPlanPath = Join-Path $modFolder "foliage\hemp\hempFieldIntegrationPlan.xml"
$processingPath = Join-Path $modFolder "xml\productions\hempProcessingRecipes.xml"

$modDesc = Read-Xml $modDescPath
$greenhouse = Read-Xml $greenhousePath
$fillTypes = Read-Xml $fillTypesPath
$fruitTypes = Read-Xml $fruitTypesPath
$growth = Read-Xml $growthPath
$foliagePlan = Read-Xml $foliagePlanPath
$integrationPlan = Read-Xml $integrationPlanPath
$processing = Read-Xml $processingPath

if ($null -ne $modDesc) {
    if ($modDesc.modDesc.descVersion -eq "91") { Pass "modDesc descVersion is 91" } else { Warn "modDesc descVersion is $($modDesc.modDesc.descVersion)" }
    if ($modDesc.modDesc.version -eq $expectedVersion) { Pass "mod version is $expectedVersion" } else { Fail "mod version is $($modDesc.modDesc.version), expected $expectedVersion" }
    if ($modDesc.modDesc.iconFilename -eq "icon_mod.dds") { Pass "mod icon points to icon_mod.dds" } else { Fail "mod iconFilename is not icon_mod.dds" }

    $storeItemPath = $modDesc.modDesc.storeItems.storeItem.xmlFilename
    if ($storeItemPath -eq "placeables/greenhouses/hempGreenhouse.xml") { Pass "greenhouse store item is active" } else { Fail "greenhouse store item path is incorrect" }

    if ($null -eq $modDesc.modDesc.fruitTypes) { Pass "field fruit type remains safely inactive" } else { Fail "fruitTypes was activated too early" }
}

if ($null -ne $fillTypes) {
    $fillNames = @($fillTypes.map.fillTypes.fillType | ForEach-Object { $_.name })
    foreach ($requiredFillType in @("HEMP", "GHI_HEMP_SEED", "GHI_HEMP_BIOMASS", "GHI_HEMP_FIBER", "GHI_HEMP_FLOWER", "GHI_HEMP_OIL")) {
        if ($fillNames -contains $requiredFillType) { Pass "fill type registered: $requiredFillType" } else { Fail "missing fill type: $requiredFillType" }
    }
}

if ($null -ne $fruitTypes) {
    $hempFruit = @($fruitTypes.map.fruitTypes.fruitType | Where-Object { $_.name -eq "HEMP" }) | Select-Object -First 1
    if ($null -eq $hempFruit) {
        Fail "fruitTypes.xml has no HEMP fruitType"
    }
    else {
        if ($hempFruit.general.numStateChannels -eq "4") { Pass "HEMP uses four state channels" } else { Fail "HEMP numStateChannels is not 4" }
        if ($hempFruit.growth.numGrowthStates -eq "7") { Pass "HEMP has seven live growth states" } else { Fail "HEMP numGrowthStates is not 7" }
        if ($hempFruit.growth.witheredState -eq "8") { Pass "HEMP withered state is 8" } else { Fail "HEMP withered state is not 8" }
        if ($hempFruit.harvest.cutState -eq "9") { Pass "HEMP cut state is 9" } else { Fail "HEMP cut state is not 9" }
    }
}

if ($null -ne $growth) {
    $hempGrowth = @($growth.growth.fruit | Where-Object { $_.name -eq "HEMP" }) | Select-Object -First 1
    if ($null -eq $hempGrowth) {
        Fail "hempGrowth.xml has no HEMP fruit"
    }
    else {
        $periods = @($hempGrowth.period)
        if ($periods.Count -eq 12) { Pass "HEMP growth calendar has 12 periods" } else { Fail "HEMP growth calendar has $($periods.Count) periods" }
    }
}

if ($null -ne $foliagePlan) {
    $rootNode = $foliagePlan.greenHorizonFoliagePlan
    if ($rootNode.fruitType -eq "HEMP") { Pass "foliage plan targets HEMP" } else { Fail "foliage plan does not target HEMP" }
    if (@($rootNode.growthStates.state).Count -eq 9) { Pass "foliage plan covers states 1 through 9" } else { Fail "foliage state count is incorrect" }

    $unsafeGates = @($rootNode.activationGates.gate | Where-Object { $_.id -ne "sourceGenerator" -and $_.complete -eq "true" })
    if ($unsafeGates.Count -eq 0) { Pass "field-crop activation gates remain closed" } else { Warn "$($unsafeGates.Count) field-crop gates are marked complete" }
}

if ($null -ne $integrationPlan) {
    $rootNode = $integrationPlan.greenHorizonFieldIntegration
    if ($rootNode.fruitType -eq "HEMP") { Pass "field integration plan targets HEMP" } else { Fail "field integration plan does not target HEMP" }
}

if ($null -ne $processing) {
    $recipes = @($processing.greenHorizonIndustries.productionRecipes.recipe)
    if ($recipes.Count -eq 4) { Pass "processing plan has four recipes" } else { Fail "processing plan has $($recipes.Count) recipes instead of four" }

    $earlyRequirements = @($processing.greenHorizonIndustries.activationRequirements.requirement | Where-Object { $_.complete -eq "true" })
    if ($earlyRequirements.Count -eq 0) { Pass "processing activation requirements remain open" } else { Warn "$($earlyRequirements.Count) processing requirements are marked complete" }
}

$palletSpecs = @(
    @{ File = "hempPallet.xml"; FillType = "HEMP"; I3d = "../i3d/hempPallet.i3d" },
    @{ File = "seedPallet.xml"; FillType = "GHI_HEMP_SEED"; I3d = "../i3d/seedPallet.i3d" },
    @{ File = "biomassPallet.xml"; FillType = "GHI_HEMP_BIOMASS"; I3d = "../i3d/biomassPallet.i3d" },
    @{ File = "fiberPallet.xml"; FillType = "GHI_HEMP_FIBER"; I3d = "../i3d/fiberPallet.i3d" },
    @{ File = "flowerPallet.xml"; FillType = "GHI_HEMP_FLOWER"; I3d = "../i3d/flowerPallet.i3d" },
    @{ File = "oilPallet.xml"; FillType = "GHI_HEMP_OIL"; I3d = "../i3d/oilPallet.i3d" }
)

foreach ($spec in $palletSpecs) {
    $path = Join-Path $modFolder ("pallets\xml\" + $spec.File)
    $xml = Read-Xml $path
    if ($null -eq $xml) { continue }

    if ($xml.vehicle.type -eq "pallet") { Pass "$($spec.File) type is pallet" } else { Fail "$($spec.File) type is not pallet" }
    if ($xml.vehicle.base.filename -eq $spec.I3d) { Pass "$($spec.File) i3d target is correct" } else { Fail "$($spec.File) i3d target is incorrect" }

    $fillUnit = $xml.vehicle.fillUnit.fillUnitConfigurations.fillUnitConfiguration.fillUnits.fillUnit
    if ($fillUnit.fillTypes -eq $spec.FillType) { Pass "$($spec.File) fill type is $($spec.FillType)" } else { Fail "$($spec.File) fill type is incorrect" }
}

if ($null -ne $greenhouse) {
    if ($greenhouse.placeable.type -eq "greenhouse") { Pass "placeable type is greenhouse" } else { Fail "placeable type is not greenhouse" }
    if ($greenhouse.placeable.storeData.category -eq "placeableMisc") { Pass "store category is placeableMisc" } else { Fail "store category is not placeableMisc" }
    if ($greenhouse.placeable.storeData.brush.tab -eq "greenhouses") { Pass "brush tab is greenhouses" } else { Fail "brush tab is not greenhouses" }

    $mappingIds = @($greenhouse.placeable.i3dMappings.i3dMapping | ForEach-Object { $_.id })
    foreach ($requiredMapping in @("clearAreaStart01", "levelAreaStart01", "indoorArea01Start", "testAreaStart01", "plantNodes", "sellingStation", "exactFillRootNode", "playerTrigger", "infoTrigger")) {
        if ($mappingIds -contains $requiredMapping) { Pass "i3d mapping exists: $requiredMapping" } else { Fail "missing i3d mapping: $requiredMapping" }
    }

    if ($greenhouse.placeable.base.filename -eq "placeables/greenhouses/i3d/greenHorizonHempGreenhouse.i3d") {
        Pass "greenhouse XML points to final i3d path"
    }
    else {
        Fail "greenhouse XML i3d path is incorrect"
    }
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
