param(
    [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"
$expectedVersion = "0.2.13.0"
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
        if ($relativePath -eq "xml/fruitTypes.xml") {
            Warn "Missing inactive draft file: $relativePath"
        }
        else {
            Fail "Missing required file: $relativePath"
        }
    }
}

$modDescPath = Join-Path $modFolder "modDesc.xml"
$greenhousePath = Join-Path $modFolder "placeables\greenhouses\hempGreenhouse.xml"
$fillTypesPath = Join-Path $modFolder "xml\fillTypes.xml"

$modDesc = if (Test-Path $modDescPath) { Read-Xml $modDescPath } else { $null }
$greenhouse = if (Test-Path $greenhousePath) { Read-Xml $greenhousePath } else { $null }
$fillTypes = if (Test-Path $fillTypesPath) { Read-Xml $fillTypesPath } else { $null }

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
}

if ($null -ne $fillTypes) {
    $names = @($fillTypes.map.fillTypes.fillType | ForEach-Object { $_.name })
    foreach ($requiredFillType in @("HEMP", "GHI_HEMP_SEED", "GHI_HEMP_BIOMASS", "GHI_HEMP_FIBER", "GHI_HEMP_FLOWER", "GHI_HEMP_OIL")) {
        if ($names -contains $requiredFillType) { Pass "fill type registered: $requiredFillType" } else { Fail "missing fill type: $requiredFillType" }
    }
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
