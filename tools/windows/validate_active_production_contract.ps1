param(
    [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"
$failures = New-Object System.Collections.Generic.List[string]

function Pass([string]$Message) {
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Fail([string]$Message) {
    $failures.Add($Message) | Out-Null
    Write-Host "FAIL: $Message" -ForegroundColor Red
}

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

function Read-Xml([string]$Path) {
    try {
        return [xml](Get-Content -Path $Path -Raw)
    }
    catch {
        Fail "XML parse failed: $Path -- $($_.Exception.Message)"
        return $null
    }
}

function Get-InputFillTypes($Production) {
    return @($Production.inputs.input | ForEach-Object { [string]$_.fillType })
}

function Get-OutputFillTypes($Production) {
    return @($Production.outputs.output | ForEach-Object { [string]$_.fillType })
}

function Assert-ContainsAll {
    param(
        [string[]]$Actual,
        [string[]]$Expected,
        [string]$Description
    )

    $missing = @($Expected | Where-Object { $Actual -notcontains $_ })
    if ($missing.Count -eq 0) {
        Pass $Description
    }
    else {
        Fail "$Description; missing: $($missing -join ', ')"
    }
}

function Resolve-ModContentPath {
    param(
        [string]$ModFolder,
        [string]$RelativePath,
        [string]$Description
    )

    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        Fail "$Description is empty"
        return $null
    }

    if ([System.IO.Path]::IsPathRooted($RelativePath)) {
        Fail "$Description must be mod-relative, not absolute: $RelativePath"
        return $null
    }

    $normalizedModFolder = [System.IO.Path]::GetFullPath($ModFolder).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    $candidate = [System.IO.Path]::GetFullPath((Join-Path $ModFolder $RelativePath))
    if (-not $candidate.StartsWith($normalizedModFolder, [System.StringComparison]::OrdinalIgnoreCase)) {
        Fail "$Description escapes the mod folder: $RelativePath"
        return $null
    }

    return $candidate
}

function Assert-ActivePalletContract {
    param(
        $FillTypesDocument,
        [string]$FillTypeName,
        [string]$ExpectedPalletXml,
        [string]$ModFolder
    )

    $fillType = @($FillTypesDocument.map.fillTypes.fillType | Where-Object { $_.name -eq $FillTypeName }) | Select-Object -First 1
    if ($null -eq $fillType) {
        Fail "Pallet fill type is not registered: $FillTypeName"
        return
    }

    $palletXmlRelative = [string]$fillType.pallet.filename
    if ($palletXmlRelative -ne $ExpectedPalletXml) {
        Fail "$FillTypeName pallet XML must be $ExpectedPalletXml (found '$palletXmlRelative')"
        return
    }

    $palletXmlPath = Resolve-ModContentPath -ModFolder $ModFolder -RelativePath $palletXmlRelative -Description "$FillTypeName pallet XML path"
    if ($null -eq $palletXmlPath) { return }
    if (-not (Test-Path -LiteralPath $palletXmlPath -PathType Leaf)) {
        Fail "$FillTypeName pallet XML does not exist: $palletXmlRelative"
        return
    }
    Pass "$FillTypeName pallet XML exists"

    $palletXml = Read-Xml $palletXmlPath
    if ($null -eq $palletXml) { return }

    $i3dRelative = [string]$palletXml.vehicle.base.filename
    if ($i3dRelative.StartsWith('$data/', [System.StringComparison]::OrdinalIgnoreCase) -or
        $i3dRelative.StartsWith('$dataS/', [System.StringComparison]::OrdinalIgnoreCase)) {
        Pass "$FillTypeName pallet uses a base-game I3D: $i3dRelative"
        return
    }

    $i3dPath = Resolve-ModContentPath -ModFolder $ModFolder -RelativePath $i3dRelative -Description "$FillTypeName pallet I3D path"
    if ($null -eq $i3dPath) { return }
    if (-not (Test-Path -LiteralPath $i3dPath -PathType Leaf)) {
        Fail "$FillTypeName pallet I3D does not exist: $i3dRelative"
        return
    }
    Pass "$FillTypeName pallet I3D exists"

    $i3d = Read-Xml $i3dPath
    if ($null -eq $i3d) { return }

    $i3dFolder = Split-Path -Parent $i3dPath
    $invalidTexture = $false
    foreach ($fileNode in @($i3d.i3D.Files.File)) {
        $textureRelative = [string]$fileNode.filename
        if ([string]::IsNullOrWhiteSpace($textureRelative)) { continue }
        $texturePath = [System.IO.Path]::GetFullPath((Join-Path $i3dFolder $textureRelative))
        $modRoot = [System.IO.Path]::GetFullPath($ModFolder).TrimEnd('\') + '\'
        if (-not $texturePath.StartsWith($modRoot, [System.StringComparison]::OrdinalIgnoreCase) -or
            -not (Test-Path -LiteralPath $texturePath -PathType Leaf)) {
            Fail "$FillTypeName pallet texture does not resolve inside the mod: $textureRelative"
            $invalidTexture = $true
        }
    }
    if (-not $invalidTexture) {
        Pass "$FillTypeName pallet texture paths resolve inside the mod"
    }

    $shapesRelative = [string]$i3d.i3D.Shapes.externalShapesFile
    if ([string]::IsNullOrWhiteSpace($shapesRelative)) {
        Fail "$FillTypeName pallet I3D does not reference an external shapes file"
        return
    }

    $shapesPath = [System.IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $i3dPath) $shapesRelative))
    if (-not (Test-Path -LiteralPath $shapesPath -PathType Leaf)) {
        Fail "$FillTypeName pallet shapes file does not exist: $shapesRelative"
        return
    }
    Pass "$FillTypeName pallet I3D and shapes file resolve inside the mod"
}

$root = Find-RepoRoot
$modFolder = Join-Path $root "FS25_GreenHorizonIndustries"

$modDesc = Read-Xml (Join-Path $modFolder "modDesc.xml")
$fillTypes = Read-Xml (Join-Path $modFolder "xml\fillTypes.xml")
$greenhouse = Read-Xml (Join-Path $modFolder "placeables\greenhouses\hempGreenhouse.xml")
$cbdPlant = Read-Xml (Join-Path $modFolder "placeables\productions\cbdPlantSmall.xml")

if ($null -ne $fillTypes) {
    $registeredFillTypes = @($fillTypes.map.fillTypes.fillType | ForEach-Object { [string]$_.name })
    Assert-ContainsAll -Actual $registeredFillTypes -Expected @(
        "HEMP",
        "GHI_HEMP_BIOMASS",
        "HEMP_FLOWER",
        "GHI_CBD_OIL"
    ) -Description "All active production fill types are registered"

    if ($registeredFillTypes -contains "GHI_HEMP_FLOWER") {
        Fail "Deprecated active fill type GHI_HEMP_FLOWER is still registered"
    }
    else {
        Pass "Deprecated GHI_HEMP_FLOWER registration is absent"
    }

    Assert-ActivePalletContract -FillTypesDocument $fillTypes -FillTypeName "HEMP" -ExpectedPalletXml "pallets/xml/hempPallet.xml" -ModFolder $modFolder
    Assert-ActivePalletContract -FillTypesDocument $fillTypes -FillTypeName "HEMP_FLOWER" -ExpectedPalletXml "pallets/xml/flowerPallet.xml" -ModFolder $modFolder
    Assert-ActivePalletContract -FillTypesDocument $fillTypes -FillTypeName "GHI_HEMP_BIOMASS" -ExpectedPalletXml "pallets/xml/biomassPallet.xml" -ModFolder $modFolder
}

if ($null -ne $modDesc) {
    $storeItems = @($modDesc.modDesc.storeItems.storeItem)
    $activePaths = @($storeItems | ForEach-Object { [string]$_.xmlFilename })

    foreach ($requiredPath in @(
        "placeables/greenhouses/hempGreenhouse.xml",
        "placeables/productions/cbdPlantSmall.xml",
        "pallets/xml/cbdOilPallet.xml"
    )) {
        $matches = @($activePaths | Where-Object { $_ -eq $requiredPath })
        if ($matches.Count -eq 1) {
            Pass "Store item registered once: $requiredPath"
        }
        else {
            Fail "Store item must be registered exactly once: $requiredPath (found $($matches.Count))"
        }
    }

    $cbdPalletItem = @($storeItems | Where-Object { $_.xmlFilename -eq "pallets/xml/cbdOilPallet.xml" }) | Select-Object -First 1
    if ($null -ne $cbdPalletItem -and [string]$cbdPalletItem.isHidden -eq "true") {
        Pass "CBD oil pallet is registered as a hidden store item"
    }
    else {
        Fail "CBD oil pallet hidden store-item flag is missing or false"
    }

    $obsoleteFacility = @($activePaths | Where-Object { $_ -match "hempProcessingFacility\.xml$" })
    if ($obsoleteFacility.Count -eq 0) {
        Pass "Obsolete hempProcessingFacility.xml is not active"
    }
    else {
        Fail "Obsolete hempProcessingFacility.xml remains active in modDesc.xml"
    }
}

if ($null -ne $greenhouse) {
    $productions = @($greenhouse.placeable.productionPoint.productions.production)
    $seeded = @($productions | Where-Object { $_.id -eq "ghi_hemp_greenhouse_seeded" }) | Select-Object -First 1
    $basic = @($productions | Where-Object { $_.id -eq "ghi_hemp_greenhouse_basic" }) | Select-Object -First 1

    if ($null -eq $seeded) { Fail "Seeded greenhouse production is missing" }
    if ($null -eq $basic) { Fail "Basic greenhouse production is missing" }

    if ($null -ne $seeded) {
        Assert-ContainsAll -Actual (Get-InputFillTypes $seeded) -Expected @("WATER", "SEEDS") -Description "Seeded greenhouse inputs are WATER and SEEDS"
        Assert-ContainsAll -Actual (Get-OutputFillTypes $seeded) -Expected @("HEMP_FLOWER", "GHI_HEMP_BIOMASS") -Description "Seeded greenhouse outputs are flower and biomass"
    }

    if ($null -ne $basic) {
        Assert-ContainsAll -Actual (Get-InputFillTypes $basic) -Expected @("WATER") -Description "Basic greenhouse input includes WATER"
        Assert-ContainsAll -Actual (Get-OutputFillTypes $basic) -Expected @("HEMP", "GHI_HEMP_BIOMASS") -Description "Basic greenhouse outputs are hemp and biomass"
    }

    $station = $greenhouse.placeable.productionPoint.sellingStation
    $unloadFillTypes = @(([string]$station.unloadTrigger.fillTypes) -split "\s+" | Where-Object { $_ })
    Assert-ContainsAll -Actual $unloadFillTypes -Expected @("WATER", "SEEDS") -Description "Greenhouse exact-fill unload trigger accepts WATER and SEEDS"

    if ([string]$station.palletTrigger.fillTypes -eq "SEEDS" -and [string]$station.palletTrigger.autoUnload -eq "true") {
        Pass "Dedicated greenhouse seed pallet trigger is configured for automatic unloading"
    }
    else {
        Fail "Dedicated greenhouse seed pallet trigger contract is incorrect"
    }

    $storageFillTypes = @(([string]$greenhouse.placeable.productionPoint.storage.fillTypes) -split "\s+" | Where-Object { $_ })
    Assert-ContainsAll -Actual $storageFillTypes -Expected @("WATER", "SEEDS", "HEMP", "GHI_HEMP_BIOMASS", "HEMP_FLOWER") -Description "Greenhouse storage supports all active inputs and outputs"

    $hempPlant = @($greenhouse.placeable.greenhouse.plants.plant | Where-Object { $_.fillType -eq "HEMP" }) | Select-Object -First 1
    if ($null -ne $hempPlant -and [string]$hempPlant.xmlFilename -eq "placeables/greenhouses/hempGreenhousePlant.xml") {
        Pass "Greenhouse uses the dedicated custom hemp plant visual"
    }
    else {
        Fail "Greenhouse custom hemp plant visual is missing or incorrect"
    }

    $spawnPlace = $greenhouse.placeable.productionPoint.palletSpawner.spawnPlaces.spawnPlace
    if ([string]$spawnPlace.startNode -eq "palletAreaStart" -and [string]$spawnPlace.endNode -eq "palletAreaEnd") {
        Pass "Greenhouse pallet spawner uses the nested start/end mapping contract"
    }
    else {
        Fail "Greenhouse pallet spawner mapping contract is incorrect"
    }

    $mappingIds = @($greenhouse.placeable.i3dMappings.i3dMapping | ForEach-Object { [string]$_.id })
    Assert-ContainsAll -Actual $mappingIds -Expected @(
        "exactFillRootNode",
        "seedPalletTrigger",
        "playerTrigger",
        "door1Trigger",
        "palletSpawner",
        "palletAreaStart",
        "palletAreaEnd"
    ) -Description "Greenhouse active trigger and pallet mappings are present"
}

if ($null -ne $cbdPlant) {
    $productions = @($cbdPlant.placeable.productionPoint.productions.production)
    $hempRecipe = @($productions | Where-Object { $_.id -eq "ghi_cbd_oil_hemp" }) | Select-Object -First 1
    $flowerRecipe = @($productions | Where-Object { $_.id -eq "ghi_cbd_oil_flower" }) | Select-Object -First 1

    if ($null -eq $hempRecipe) { Fail "CBD HEMP recipe is missing" }
    if ($null -eq $flowerRecipe) { Fail "CBD HEMP_FLOWER recipe is missing" }

    if ($null -ne $hempRecipe) {
        Assert-ContainsAll -Actual (Get-InputFillTypes $hempRecipe) -Expected @("HEMP") -Description "CBD hemp recipe accepts HEMP"
        Assert-ContainsAll -Actual (Get-OutputFillTypes $hempRecipe) -Expected @("GHI_CBD_OIL") -Description "CBD hemp recipe outputs GHI_CBD_OIL"
    }

    if ($null -ne $flowerRecipe) {
        Assert-ContainsAll -Actual (Get-InputFillTypes $flowerRecipe) -Expected @("HEMP_FLOWER") -Description "CBD flower recipe accepts HEMP_FLOWER"
        Assert-ContainsAll -Actual (Get-OutputFillTypes $flowerRecipe) -Expected @("GHI_CBD_OIL") -Description "CBD flower recipe outputs GHI_CBD_OIL"
    }

    $storageFillTypes = @($cbdPlant.placeable.productionPoint.storage.capacity | ForEach-Object { [string]$_.fillType })
    Assert-ContainsAll -Actual $storageFillTypes -Expected @("HEMP", "HEMP_FLOWER", "GHI_CBD_OIL") -Description "CBD storage supports both inputs and CBD oil"

    $unloadFillTypes = @(([string]$cbdPlant.placeable.productionPoint.sellingStation.unloadTrigger.fillTypes) -split "\s+" | Where-Object { $_ })
    Assert-ContainsAll -Actual $unloadFillTypes -Expected @("HEMP", "HEMP_FLOWER") -Description "CBD unloading accepts both greenhouse products"

    $cbdPalletTrigger = $cbdPlant.placeable.productionPoint.sellingStation.palletTrigger
    $cbdPalletFillTypes = @(([string]$cbdPalletTrigger.fillTypes) -split "\s+" | Where-Object { $_ })
    Assert-ContainsAll -Actual $cbdPalletFillTypes -Expected @("HEMP", "HEMP_FLOWER") -Description "CBD physical pallet trigger accepts hemp and flower pallets"
    if ([string]$cbdPalletTrigger.triggerNode -eq "palletTrigger" -and [string]$cbdPalletTrigger.autoUnload -eq "true") {
        Pass "CBD physical pallet trigger uses the marked unload zone with automatic unloading"
    }
    else {
        Fail "CBD physical pallet trigger contract is incorrect"
    }

    $spawnPlace = $cbdPlant.placeable.productionPoint.palletSpawner.spawnPlaces.spawnPlace
    if ([string]$spawnPlace.startNode -eq "palletAreaStart01" -and [string]$spawnPlace.endNode -eq "palletAreaEnd01") {
        Pass "CBD pallet spawner uses the nested start/end mapping contract"
    }
    else {
        Fail "CBD pallet spawner mapping contract is incorrect"
    }
}

Write-Host ""
Write-Host "Active production contract summary" -ForegroundColor Cyan
Write-Host "Failures: $($failures.Count)"

if ($failures.Count -gt 0) {
    exit 1
}

Write-Host "Active production contract passed." -ForegroundColor Green
exit 0
