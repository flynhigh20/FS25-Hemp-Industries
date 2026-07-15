param(
    [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"
$failures = New-Object System.Collections.Generic.List[string]

function Pass([string]$Message) { Write-Host "PASS: $Message" -ForegroundColor Green }
function Fail([string]$Message) { $failures.Add($Message) | Out-Null; Write-Host "FAIL: $Message" -ForegroundColor Red }

function Find-RepoRoot {
    if (-not [string]::IsNullOrWhiteSpace($RepoRoot)) { return (Resolve-Path $RepoRoot).Path }
    $current = Resolve-Path (Split-Path -Parent $PSCommandPath)
    while ($null -ne $current) {
        if (Test-Path (Join-Path $current "FS25_GreenHorizonIndustries\modDesc.xml")) { return $current.Path }
        $parent = Split-Path -Parent $current
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $current.Path) { break }
        $current = Resolve-Path $parent
    }
    throw "Could not find repository root."
}

function Read-Xml([string]$Path) {
    try { return [xml](Get-Content -LiteralPath $Path -Raw) }
    catch { Fail "XML parse failed: $Path -- $($_.Exception.Message)"; return $null }
}

function Assert-File([string]$Path, [string]$Description) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) { Pass $Description } else { Fail "$Description is missing: $Path" }
}

$root = Find-RepoRoot
$modFolder = Join-Path $root "FS25_GreenHorizonIndustries"
$modDesc = Read-Xml (Join-Path $modFolder "modDesc.xml")
$fruitTypes = Read-Xml (Join-Path $modFolder "xml\fruitTypes.xml")
$growth = Read-Xml (Join-Path $modFolder "xml\growth\hempGrowth.xml")
$registration = Read-Xml (Join-Path $modFolder "foliage\hemp\hempMapRegistrationDraft.xml")
$foliagePlan = Read-Xml (Join-Path $modFolder "foliage\hemp\hempFoliagePlan.xml")
$cutterPlan = Read-Xml (Join-Path $modFolder "foliage\hemp\hempCutterEffectsPlan.xml")

if ($null -ne $modDesc) {
    if ($null -eq $modDesc.modDesc.fruitTypes) { Pass "Field fruit type remains safely inactive in modDesc.xml" }
    else { Fail "fruitTypes was activated before controlled-map validation" }
}

if ($null -ne $fruitTypes) {
    $hemp = @($fruitTypes.map.fruitTypes.fruitType | Where-Object { $_.name -eq "HEMP" }) | Select-Object -First 1
    if ($null -eq $hemp) { Fail "HEMP fruit type draft is missing" }
    else {
        if ([string]$hemp.general.numStateChannels -eq "4") { Pass "HEMP uses four state channels" } else { Fail "HEMP numStateChannels must be 4" }
        if ([string]$hemp.growth.numGrowthStates -eq "7") { Pass "HEMP has seven growth states" } else { Fail "HEMP numGrowthStates must be 7" }
        if ([string]$hemp.harvest.minHarvestingGrowthState -eq "7" -and [string]$hemp.harvest.maxHarvestingGrowthState -eq "7") { Pass "HEMP harvest-ready state is 7" } else { Fail "HEMP harvest-ready state must be exactly 7" }
        if ([string]$hemp.growth.witheredState -eq "8") { Pass "HEMP withered state is 8" } else { Fail "HEMP withered state must be 8" }
        if ([string]$hemp.harvest.cutState -eq "9") { Pass "HEMP cut state is 9" } else { Fail "HEMP cut state must be 9" }
    }
}

if ($null -ne $registration) {
    $contract = $registration.greenHorizonMapRegistration.stateContract
    $expected = @{
        numStateChannels = "4"
        numGrowthStates = "7"
        harvestReadyState = "7"
        witheredState = "8"
        cutState = "9"
    }
    foreach ($key in $expected.Keys) {
        if ([string]$contract.$key -eq $expected[$key]) { Pass "Map registration $key is $($expected[$key])" }
        else { Fail "Map registration $key must be $($expected[$key])" }
    }

    $selectedWorkflows = @($registration.greenHorizonMapRegistration.firstVehicleWorkflow.* | Where-Object { $_.selected -eq "true" })
    if ($selectedWorkflows.Count -eq 0) { Pass "No unverified field vehicle workflow is selected" }
    else { Fail "A field vehicle workflow was selected before testing" }

    $completedRequirements = @($registration.greenHorizonMapRegistration.mapIntegrationChecklist.requirement | Where-Object { $_.complete -eq "true" })
    if ($completedRequirements.Count -eq 0) { Pass "Controlled-map checklist remains unclaimed" }
    else { Fail "Controlled-map requirements were marked complete without test evidence" }
}

$requiredAssets = @(
    "foliage/hemp/textures/hempFoliage_diffuse.png",
    "foliage/hemp/textures/hempFoliage_normal.png",
    "foliage/hemp/textures/hempFoliage_distance_diffuse.png",
    "foliage/hemp/textures/hempFoliage_distance_normal.png",
    "foliage/hemp/effects/textures/hemp_chaff_diffuse.png",
    "foliage/hemp/effects/textures/hemp_stem_shard_diffuse.png",
    "foliage/hemp/effects/textures/hemp_leaf_fragment_diffuse.png",
    "foliage/hemp/effects/textures/hemp_dust_diffuse.png",
    "ui/icons/crop_hemp.png",
    "ui/icons/calendar_hemp.png",
    "ui/icons/fillType_hemp.png"
)
foreach ($relative in $requiredAssets) {
    Assert-File -Path (Join-Path $modFolder ($relative.Replace('/', '\'))) -Description "Phase 3 asset exists: $relative"
}

foreach ($document in @(
    @{ Value = $growth; Name = "growth calendar" },
    @{ Value = $foliagePlan; Name = "foliage plan" },
    @{ Value = $cutterPlan; Name = "cutter-effects plan" }
)) {
    if ($null -ne $document.Value) { Pass "$($document.Name) parses as XML" }
}

Write-Host ""
Write-Host "Phase 3 field-hemp foundation summary" -ForegroundColor Cyan
Write-Host "Failures: $($failures.Count)"
if ($failures.Count -gt 0) { exit 1 }
Write-Host "Phase 3 foundation passed. Fruit registration remains intentionally inactive." -ForegroundColor Green
exit 0
