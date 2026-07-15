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
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $current.Path) { break }
        $current = Resolve-Path $parent
    }

    throw "Could not find repository root."
}

$root = Find-RepoRoot
$modFolder = Join-Path $root "FS25_GreenHorizonIndustries"
$greenhouseI3dPath = Join-Path $modFolder "placeables\greenhouses\i3d\greenHorizonHempGreenhouse.i3d"
$fieldTexturePaths = @(
    "foliage\hemp\textures\hempFoliage_diffuse.png",
    "foliage\hemp\textures\hempFoliage_normal.png",
    "foliage\hemp\textures\hempFoliage_distance_diffuse.png",
    "foliage\hemp\textures\hempFoliage_distance_normal.png"
)

if (-not (Test-Path -LiteralPath $greenhouseI3dPath -PathType Leaf)) {
    Fail "Greenhouse I3D is missing"
}
else {
    try {
        [xml]$greenhouseI3d = Get-Content -LiteralPath $greenhouseI3dPath -Raw
        Pass "Greenhouse I3D parses"

        $fileNames = @($greenhouseI3d.i3D.Files.File | ForEach-Object { [string]$_.filename })
        foreach ($requiredTexture in @(
            "../textures/greenhouse_hemp_leaf_diffuse.dds",
            "../textures/greenhouse_stem_diffuse.dds"
        )) {
            if ($fileNames -contains $requiredTexture) {
                Pass "Greenhouse hemp texture registered: $requiredTexture"
            }
            else {
                Fail "Greenhouse hemp texture is missing from I3D: $requiredTexture"
            }
        }

        $materialNames = @($greenhouseI3d.i3D.Materials.Material | ForEach-Object { [string]$_.name })
        foreach ($requiredMaterial in @("industrialHempLeaf", "hempStemGreenBrown")) {
            if ($materialNames -contains $requiredMaterial) {
                Pass "Greenhouse hemp material present: $requiredMaterial"
            }
            else {
                Fail "Greenhouse hemp material missing: $requiredMaterial"
            }
        }

        $sceneXml = $greenhouseI3d.i3D.Scene.OuterXml
        $plantNodeCount = ([regex]::Matches($sceneXml, 'name="plantNode(?:1[0-5]|[1-9])"')).Count
        if ($plantNodeCount -eq 15) {
            Pass "All 15 greenhouse plant anchor nodes are present"
        }
        else {
            Fail "Expected 15 greenhouse plant anchor nodes; found $plantNodeCount"
        }

        $hempLeafCount = ([regex]::Matches($sceneXml, 'name="hempLeaf')).Count
        $hempStemCount = ([regex]::Matches($sceneXml, 'name="hempStem')).Count
        if ($hempLeafCount -gt 0 -and $hempStemCount -gt 0) {
            Pass "Greenhouse contains hemp leaf and stem geometry"
        }
        else {
            Fail "Greenhouse hemp geometry is incomplete (leaves=$hempLeafCount stems=$hempStemCount)"
        }

        if ($sceneXml -match '(?i)lettuce') {
            Fail "Greenhouse I3D still contains a lettuce reference"
        }
        else {
            Pass "No lettuce references remain in greenhouse I3D"
        }
    }
    catch {
        Fail "Greenhouse I3D parse failed: $($_.Exception.Message)"
    }
}

foreach ($relativePath in $fieldTexturePaths) {
    $fullPath = Join-Path $modFolder $relativePath
    if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
        Pass "Phase 3 field foliage asset exists: $relativePath"
    }
    else {
        Fail "Phase 3 field foliage asset missing: $relativePath"
    }
}

Write-Host ""
if ($failures.Count -gt 0) {
    Write-Host "Greenhouse hemp visual validation failed with $($failures.Count) issue(s)." -ForegroundColor Red
    foreach ($failure in $failures) { Write-Host " - $failure" -ForegroundColor Red }
    exit 1
}

Write-Host "Greenhouse hemp visual validation passed." -ForegroundColor Green
exit 0
