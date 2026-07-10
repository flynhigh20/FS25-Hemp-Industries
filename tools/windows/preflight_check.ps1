param(
    [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"
$expectedVersion = "0.2.15.0"
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

$root = Find-RepoRoot
$modFolder = Join-Path $root "FS25_GreenHorizonIndustries"

$requiredFiles = @(
    "modDesc.xml",
    "icon_mod.dds",
    "xml/fillTypes.xml",
    "xml/fruitTypes.xml",
    "xml/growth/hempGrowth.xml",
    "foliage/hemp/hempFoliagePlan.xml",
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

$modDescPath = Join-Path $modFolder "modDesc.xml"
$greenhousePath = Join-Path $modFolder "placeables\greenhouses\hempGreenhouse.xml"
$fillTypesPath = Join-Path $modFolder "xml\fillTypes.xml"
$fruitTypesPath = Join-Path $modFolder "xml\fruitTypes.xml"
$growthPath = Join-Path $modFolder "xml\growth\hempGrowth.xml"
$foliagePlanPath = Join-Path $modFolder "foliage\hemp\hempFoliagePlan.xml"

$modDesc = if (Test-Path $modDescPath) { Read-Xml $modDescPath } else { $null }
$greenhouse = if (Test-Path $greenhousePath) { Read-Xml $greenhousePath } else { $null }
$fillTypes = if (Test-Path $fillTypesPath) { Read-Xml $fillTypesPath } else { $null }
$fruitTypes = if (Test-Path $fruitTypesPath) { Read-Xml $fruitTypesPath } else { $null }
$growth = if (Test-Path $growthPath) { Read-Xml $growthPath } else { $null }
$foliagePlan = if (Test-Path $foliagePlanPath) { Read-Xml $foliagePlanPath } else { $null }

if ($null -ne $modDesc) {
    if ($modDesc.modDesc.descVersion -eq "91") { Pass "modDesc descVersion is 91" } else { Warn "modDesc descVersion is $($modDesc.modDesc.descVersion)" }
    if ($modDesc.modDesc.version -eq $expectedVersion) { Pass "mod version is $expectedVersion" } else { Fail "mod version is $($modDesc.modDesc.version), expected $expectedVersion" }
    if ($modDesc.modDesc.iconFilename -eq "icon_mod.dds") { Pass "mod icon points to icon_mod.dds" } else { Fail "mod iconFilename is not icon_mod.dds" }

    $storeItemPath = $modDesc.modDesc.storeItems.storeItem.xmlFilename
    if ($storeItemPath -eq "placeables/greenhouses/hempGreenhouse.xml") {
        Pass "greenhouse store item is active"
    }
    else {
        Fail "greenhouse store item path is incorrect"
    }

    if ($null -eq $modDesc.modDesc.fruitTypes) {
        Pass "field fruit type remains safely inactive"
    }
    else {
        Fail "fruitTypes was activated before map foliage integration is ready"
    }
}

if ($null -ne $fillTypes) {
    $names = @($fillTypes.map.fillTypes.fillType | ForEach-Object { $_.name })
    foreach ($requiredFillType in @("HEMP", "GHI_HEMP_SEED", "GHI_HEMP_BIOMASS", "GHI_HEMP_FIBER", "GHI_HEMP_FLOWER", "GHI_HEMP_OIL")) {
        if ($names -contains $requiredFillType) { Pass "fill type registered: $requiredFillType" } else { Fail "missing fill type: $requiredFillType" }
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
        if ($hempFruit.harvest.minHarvestingGrowthState -eq "7") { Pass "HEMP harvest-ready state is 7" } else { Fail "HEMP harvest-ready state is not 7" }
    }
}

if ($null -ne $growth) {
    $hempGrowth = @($growth.growth.fruit | Where-Object { $_.name -eq "HEMP" }) | Select-Object -First 1
    if ($null -eq $hempGrowth) {
        Fail "hempGrowth.xml has no HEMP fruit"
    }
    else {
        $periods = @($hempGrowth.period)
        if ($periods.Count -eq 12) { Pass "HEMP growth calendar has 12 periods" } else { Fail "HEMP growth calendar has $($periods.Count) periods instead of 12" }
        $plantingPeriods = @($periods | Where-Object { $_.plantingAllowed -eq "true" })
        if ($plantingPeriods.Count -ge 2) { Pass "HEMP has a defined planting window" } else { Warn "HEMP planting window is very narrow" }
    }
}

if ($null -ne $foliagePlan) {
    $rootNode = $foliagePlan.greenHorizonFoliagePlan
    if ($rootNode.fruitType -eq "HEMP") { Pass "foliage plan targets HEMP" } else { Fail "foliage plan does not target HEMP" }

    $states = @($rootNode.growthStates.state)
    if ($states.Count -eq 9) { Pass "foliage plan covers states 1 through 9" } else { Fail "foliage plan has $($states.Count) states instead of 9" }

    $gates = @($rootNode.activationGates.gate)
    $premature = @($gates | Where-Object { $_.complete -eq "true" })
    if ($premature.Count -eq 0) { Pass "foliage activation gates remain closed" } else { Warn "$($premature.Count) foliage activation gates are marked complete" }
}

if ($null -ne $greenhouse) {
    if ($greenhouse.placeable.type -eq "greenhouse") { Pass "placeable type is greenhouse" } else { Fail "placeable type is not greenhouse" }
    if ($greenhouse.placeable.storeData.category -eq "placeableMisc") { Pass "store category is placeableMisc" } else { Fail "store category is not placeableMisc" }
    if ($greenhouse.placeable.storeData.brush.tab -eq "greenhouses") { Pass "brush tab is greenhouses" } else { Fail "brush tab is not greenhouses" }

    $mappingIds = @($greenhouse.placeable.i3dMappings.i3dMapping | ForEach-Object { $_.id })
    foreach ($requiredMapping in @(
        "clearAreaStart01",
        "levelAreaStart01",
        "indoorArea01Start",
        "testAreaStart01",
        "plantNodes",
        "sellingStation",
        "exactFillRootNode",
        "playerTrigger",
        "infoTrigger"
    )) {
        if ($mappingIds -contains $requiredMapping) { Pass "i3d mapping exists: $requiredMapping" } else { Fail "missing i3d mapping: $requiredMapping" }
    }

    $i3dFilename = $greenhouse.placeable.base.filename
    if ($i3dFilename -eq "placeables/greenhouses/i3d/greenHorizonHempGreenhouse.i3d") {
        Pass "greenhouse XML points to final i3d path"
    }
    else {
        Fail "greenhouse XML i3d path is incorrect: $i3dFilename"
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
