param(
    [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"
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

function Check-OptionalAssetSet {
    param(
        [string]$BaseFolder,
        [string[]]$RelativePaths,
        [string]$Label,
        [string]$Generator
    )

    $count = 0
    foreach ($relativePath in $RelativePaths) {
        $fullPath = Join-Path $BaseFolder ($relativePath.Replace("/", "\"))
        if (Test-Path $fullPath) {
            $count += 1
            Pass "$Label exists: $relativePath"
        }
    }

    if ($count -eq 0) {
        Warn "$Label assets are not generated yet. Run $Generator in Blender later."
    }
    elseif ($count -ne $RelativePaths.Count) {
        Fail "Only $count of $($RelativePaths.Count) $Label assets exist."
    }
}

$root = Find-RepoRoot
$modFolder = Join-Path $root "FS25_GreenHorizonIndustries"

$paths = @{
    ModDesc = Join-Path $modFolder "modDesc.xml"
    FillTypes = Join-Path $modFolder "xml\fillTypes.xml"
    FruitTypes = Join-Path $modFolder "xml\fruitTypes.xml"
    Growth = Join-Path $modFolder "xml\growth\hempGrowth.xml"
    Foliage = Join-Path $modFolder "foliage\hemp\hempFoliagePlan.xml"
    Cutter = Join-Path $modFolder "foliage\hemp\hempCutterEffectsPlan.xml"
    MapDraft = Join-Path $modFolder "foliage\hemp\hempMapRegistrationDraft.xml"
    Integration = Join-Path $modFolder "foliage\hemp\hempFieldIntegrationPlan.xml"
    Icons = Join-Path $modFolder "ui\hempIconManifest.xml"
}

Write-Host "Green Horizon Industries - Field Hemp Foundation Check" -ForegroundColor Cyan
Write-Host ""

foreach ($entry in $paths.GetEnumerator()) {
    if (Test-Path $entry.Value) {
        Pass "Found $($entry.Key): $($entry.Value)"
    }
    else {
        Fail "Missing $($entry.Key): $($entry.Value)"
    }
}

$requiredGenerators = @(
    "tools/blender/create_hemp_foliage.py",
    "tools/blender/create_hemp_crop_icons.py",
    "tools/blender/create_hemp_cutter_effects.py"
)

foreach ($relativePath in $requiredGenerators) {
    $fullPath = Join-Path $root ($relativePath.Replace("/", "\"))
    if (Test-Path $fullPath) { Pass "Found $relativePath" } else { Fail "Missing $relativePath" }
}

$modDesc = Read-Xml $paths.ModDesc
$fillTypes = Read-Xml $paths.FillTypes
$fruitTypes = Read-Xml $paths.FruitTypes
$growth = Read-Xml $paths.Growth
$foliage = Read-Xml $paths.Foliage
$cutter = Read-Xml $paths.Cutter
$mapDraft = Read-Xml $paths.MapDraft
$integration = Read-Xml $paths.Integration
$icons = Read-Xml $paths.Icons

if ($null -ne $modDesc) {
    if ($null -eq $modDesc.modDesc.fruitTypes) {
        Pass "fruitTypes.xml remains excluded from modDesc.xml"
    }
    else {
        Fail "fruitTypes.xml is active before field integration is ready"
    }

    $descriptorText = Get-Content -Path $paths.ModDesc -Raw
    foreach ($forbidden in @("hempCutterEffectsPlan.xml", "hempMapRegistrationDraft.xml", "hempIconManifest.xml")) {
        if ($descriptorText -match [regex]::Escape($forbidden) -and $descriptorText -notmatch "Prepared but deliberately inactive") {
            Warn "$forbidden appears in modDesc.xml outside the inactive documentation block"
        }
    }
}

$requiredFillTypes = @("HEMP", "GHI_HEMP_SEED", "GHI_HEMP_BIOMASS", "GHI_HEMP_FIBER", "GHI_HEMP_FLOWER", "GHI_HEMP_OIL")
if ($null -ne $fillTypes) {
    $fillTypeNames = @($fillTypes.map.fillTypes.fillType | ForEach-Object { $_.name })
    foreach ($fillTypeName in $requiredFillTypes) {
        if ($fillTypeNames -contains $fillTypeName) { Pass "Fill type exists: $fillTypeName" } else { Fail "Missing fill type: $fillTypeName" }
    }
}

$contracts = @()
if ($null -ne $fruitTypes) {
    $fruit = @($fruitTypes.map.fruitTypes.fruitType | Where-Object { $_.name -eq "HEMP" }) | Select-Object -First 1
    if ($null -eq $fruit) {
        Fail "fruitTypes.xml has no HEMP fruitType"
    }
    else {
        $contracts += [pscustomobject]@{
            Source = "fruitTypes.xml"
            Channels = [int]$fruit.general.numStateChannels
            Growth = [int]$fruit.growth.numGrowthStates
            Harvest = [int]$fruit.harvest.minHarvestingGrowthState
            Withered = [int]$fruit.growth.witheredState
            Cut = [int]$fruit.harvest.cutState
        }
    }
}

if ($null -ne $foliage) {
    $node = $foliage.greenHorizonFoliagePlan.densityMap
    $contracts += [pscustomobject]@{
        Source = "hempFoliagePlan.xml"
        Channels = [int]$node.numStateChannels
        Growth = [int]$node.numGrowthStates
        Harvest = [int]$node.harvestReadyState
        Withered = [int]$node.witheredState
        Cut = [int]$node.cutState
    }

    $states = @($foliage.greenHorizonFoliagePlan.growthStates.state)
    if ($states.Count -eq 9) { Pass "Foliage plan has nine states" } else { Fail "Foliage plan has $($states.Count) states" }
}

if ($null -ne $mapDraft) {
    $node = $mapDraft.greenHorizonMapRegistration.stateContract
    $contracts += [pscustomobject]@{
        Source = "hempMapRegistrationDraft.xml"
        Channels = [int]$node.numStateChannels
        Growth = [int]$node.numGrowthStates
        Harvest = [int]$node.harvestReadyState
        Withered = [int]$node.witheredState
        Cut = [int]$node.cutState
    }

    $mapRequirements = @($mapDraft.greenHorizonMapRegistration.mapIntegrationChecklist.requirement)
    $completed = @($mapRequirements | Where-Object { $_.complete -eq "true" })
    if ($completed.Count -eq 0) { Pass "Map activation checklist remains open" } else { Warn "$($completed.Count) map requirements are already marked complete" }
}

if ($contracts.Count -gt 1) {
    $baseline = $contracts[0]
    foreach ($contract in $contracts | Select-Object -Skip 1) {
        foreach ($property in @("Channels", "Growth", "Harvest", "Withered", "Cut")) {
            if ($contract.$property -eq $baseline.$property) {
                Pass "$($contract.Source) $property matches $($baseline.Source): $($contract.$property)"
            }
            else {
                Fail "$($contract.Source) $property=$($contract.$property) does not match $($baseline.Source)=$($baseline.$property)"
            }
        }
    }
}

if ($null -ne $growth) {
    $hempGrowth = @($growth.growth.fruit | Where-Object { $_.name -eq "HEMP" }) | Select-Object -First 1
    if ($null -eq $hempGrowth) {
        Fail "Growth calendar has no HEMP entry"
    }
    else {
        $periods = @($hempGrowth.period)
        if ($periods.Count -eq 12) { Pass "Growth calendar has 12 periods" } else { Fail "Growth calendar has $($periods.Count) periods" }
    }
}

if ($null -ne $cutter) {
    $routes = @($cutter.greenHorizonCutterEffects.cropStateRouting.route)
    $harvestRoute = @($routes | Where-Object { $_.growthState -eq "7" -and $_.cutterAllowed -eq "true" }) | Select-Object -First 1
    if ($null -ne $harvestRoute -and $harvestRoute.outputFillType -eq "HEMP" -and $harvestRoute.resultingState -eq "9") {
        Pass "Cutter route matches mature HEMP -> cut state 9"
    }
    else {
        Fail "Cutter route does not match mature HEMP -> cut state 9"
    }

    $effectRequirements = @($cutter.greenHorizonCutterEffects.activationRequirements.requirement)
    $completed = @($effectRequirements | Where-Object { $_.complete -eq "true" })
    if ($completed.Count -eq 0) { Pass "Cutter-effect activation requirements remain open" } else { Warn "$($completed.Count) cutter-effect requirements are marked complete" }
}

if ($null -ne $icons) {
    $iconEntries = @($icons.greenHorizonIconManifest.icons.icon)
    foreach ($fillTypeName in $requiredFillTypes) {
        $match = @($iconEntries | Where-Object { $_.id -eq $fillTypeName }) | Select-Object -First 1
        if ($null -ne $match) { Pass "Icon manifest includes $fillTypeName" } else { Fail "Icon manifest missing $fillTypeName" }
    }

    $linked = @($iconEntries | Where-Object { $_.linked -eq "true" })
    if ($linked.Count -eq 0) { Pass "No crop/product icons are linked early" } else { Fail "$($linked.Count) icons are marked linked before activation" }
}

if ($null -ne $integration) {
    $openRequirements = @($integration.greenHorizonFieldIntegration.mapLayer.requirement | Where-Object { $_.complete -ne "true" })
    $allRequirements = @($integration.greenHorizonFieldIntegration.mapLayer.requirement)
    if ($openRequirements.Count -eq $allRequirements.Count) { Pass "Field integration map requirements remain open" } else { Warn "Some map integration requirements are marked complete" }
}

Check-OptionalAssetSet -BaseFolder $modFolder -Label "Foliage texture" -Generator "tools/blender/create_hemp_foliage.py" -RelativePaths @(
    "foliage/hemp/textures/hempFoliage_diffuse.png",
    "foliage/hemp/textures/hempFoliage_normal.png",
    "foliage/hemp/textures/hempFoliage_distance_diffuse.png",
    "foliage/hemp/textures/hempFoliage_distance_normal.png"
)

Check-OptionalAssetSet -BaseFolder $modFolder -Label "Crop icon" -Generator "tools/blender/create_hemp_crop_icons.py" -RelativePaths @(
    "ui/icons/fillType_hemp.png",
    "ui/icons/fillType_hempSeed.png",
    "ui/icons/fillType_hempBiomass.png",
    "ui/icons/fillType_hempFiber.png",
    "ui/icons/fillType_hempFlower.png",
    "ui/icons/fillType_hempOil.png",
    "ui/icons/crop_hemp.png",
    "ui/icons/calendar_hemp.png"
)

Check-OptionalAssetSet -BaseFolder $modFolder -Label "Cutter-effect texture" -Generator "tools/blender/create_hemp_cutter_effects.py" -RelativePaths @(
    "foliage/hemp/effects/textures/hemp_chaff_diffuse.png",
    "foliage/hemp/effects/textures/hemp_stem_shard_diffuse.png",
    "foliage/hemp/effects/textures/hemp_leaf_fragment_diffuse.png",
    "foliage/hemp/effects/textures/hemp_dust_diffuse.png"
)

Write-Host ""
Write-Host "Field hemp summary" -ForegroundColor Cyan
Write-Host "Failures: $($failures.Count)"
Write-Host "Warnings: $($warnings.Count)"

if ($failures.Count -gt 0) {
    exit 1
}

Write-Host "Field hemp foundation check passed." -ForegroundColor Green
exit 0
