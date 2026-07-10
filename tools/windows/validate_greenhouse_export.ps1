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

$root = Find-RepoRoot
$i3dFolder = Join-Path $root "FS25_GreenHorizonIndustries\placeables\greenhouses\i3d"
$i3dPath = Join-Path $i3dFolder "greenHorizonHempGreenhouse.i3d"
$canonicalShapesName = "greenhorizonhempgreenhouse.i3d.shapes"
$shapesPath = Join-Path $i3dFolder $canonicalShapesName
$shapeNormalizer = Join-Path $root "tools\windows\normalize_greenhouse_shapes.ps1"
$textureNormalizer = Join-Path $root "tools\windows\normalize_greenhouse_texture_paths.ps1"

Write-Host "Green Horizon Industries - Greenhouse Export Repair and Validator" -ForegroundColor Cyan
Write-Host "I3D:    $i3dPath"
Write-Host "Shapes: $shapesPath"
Write-Host ""

if (-not (Test-Path $i3dPath)) {
    Fail "The greenhouse i3d does not exist."
    Write-Host ""
    Write-Host "Export the Blender root greenHorizonHempGreenhouse directly into the mod i3d folder." -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $shapeNormalizer)) {
    Fail "Shapes normalizer is missing: $shapeNormalizer"
}
else {
    Write-Host "Normalizing greenhouse shapes filename and i3d reference..." -ForegroundColor Cyan
    & $shapeNormalizer -RepoRoot $root
    if ($LASTEXITCODE -ne 0) {
        Fail "Shapes filename/reference normalization failed"
    }
    else {
        Pass "Shapes filename/reference normalization completed"
    }
}

if (-not (Test-Path $shapesPath)) {
    Fail "The canonical greenhouse shapes file does not exist: $canonicalShapesName"
}

if (-not (Test-Path $textureNormalizer)) {
    Fail "Texture-path normalizer is missing: $textureNormalizer"
}
else {
    Write-Host "Normalizing known greenhouse texture references..." -ForegroundColor Cyan
    & $textureNormalizer -RepoRoot $root
    if ($LASTEXITCODE -ne 0) {
        Fail "Texture-path normalization failed"
    }
    else {
        Pass "Texture-path normalization completed"
    }
}

if ($failures.Count -gt 0) {
    Write-Host ""
    Write-Host "Export repair failed before validation." -ForegroundColor Red
    exit 1
}

$i3dItem = Get-Item $i3dPath
$shapesItem = Get-Item $shapesPath

if ($i3dItem.Length -gt 4096) { Pass "i3d size looks like a real model: $($i3dItem.Length) bytes" } else { Fail "i3d is only $($i3dItem.Length) bytes and still looks like a placeholder or broken export" }
if ($shapesItem.Length -gt 1024) { Pass "shapes file contains model data: $($shapesItem.Length) bytes" } else { Fail "shapes file is only $($shapesItem.Length) bytes" }

$raw = Get-Content -Path $i3dPath -Raw

try {
    [xml]$document = $raw
    Pass "i3d XML parses successfully"
}
catch {
    Fail "i3d XML parse failed: $($_.Exception.Message)"
    $document = $null
}

if ($raw -match "placeholder" -or $raw -match "Temporary empty transform") {
    Fail "The committed Phase 2.6 placeholder i3d is still present"
}
else {
    Pass "placeholder markers are gone"
}

if ($raw -match 'filename="[A-Za-z]:[\\/]') {
    Fail "An absolute Windows filename is embedded in the i3d"
}
else {
    Pass "no absolute Windows file paths were found"
}

if ($raw -match 'filename="file:///') {
    Fail "A file:// path is embedded in the i3d"
}
else {
    Pass "no file:// paths were found"
}

if ($raw -match 'filename="[^"]*FS25_GreenHorizonIndustries[^"]*greenhouse_[^"]+_diffuse\.png"') {
    Fail "A duplicated repository path remains in a greenhouse texture filename"
}
else {
    Pass "no duplicated repository folder is embedded in greenhouse texture paths"
}

if ($raw -match ('externalShapesFile="' + [regex]::Escape($canonicalShapesName) + '"')) {
    Pass "i3d references the canonical lowercase shapes filename"
}
else {
    Fail "i3d externalShapesFile does not exactly match $canonicalShapesName"
}

$requiredNodeNames = @(
    "greenHorizonHempGreenhouse",
    "clearAreaStart01",
    "levelAreaStart01",
    "indoorArea01Start",
    "testAreaStart01",
    "plantNodes",
    "palletSpawner",
    "sellingStation",
    "exactFillRootNode",
    "storage",
    "playerTrigger",
    "infoTrigger",
    "collisions",
    "visuals"
)

foreach ($nodeName in $requiredNodeNames) {
    if ($raw -match ('name="' + [regex]::Escape($nodeName) + '"')) {
        Pass "required node exported: $nodeName"
    }
    else {
        Fail "required node is missing from i3d: $nodeName"
    }
}

$shapeCount = ([regex]::Matches($raw, '<Shape\b')).Count
$materialCount = ([regex]::Matches($raw, '<Material\b')).Count
$fileCount = ([regex]::Matches($raw, '<File\b')).Count

if ($shapeCount -ge 10) { Pass "shape count: $shapeCount" } else { Fail "only $shapeCount Shape entries were exported" }
if ($materialCount -ge 5) { Pass "material count: $materialCount" } else { Fail "only $materialCount Material entries were exported" }
if ($fileCount -ge 5) { Pass "external file count: $fileCount" } else { Fail "only $fileCount File entries were exported" }

$textureNames = @(
    "greenhouse_glass_diffuse.png",
    "greenhouse_frame_diffuse.png",
    "greenhouse_concrete_diffuse.png",
    "greenhouse_soil_diffuse.png",
    "greenhouse_hemp_leaf_diffuse.png",
    "greenhouse_stem_diffuse.png",
    "greenhouse_water_tank_diffuse.png",
    "greenhouse_rubber_diffuse.png",
    "greenhouse_wire_diffuse.png",
    "greenhouse_light_diffuse.png"
)

$referencedTextures = 0
foreach ($textureName in $textureNames) {
    $expectedReference = 'filename="../textures/' + [regex]::Escape($textureName) + '"'
    if ($raw -match $expectedReference) {
        $referencedTextures += 1
        Pass "normalized texture reference found: $textureName"
    }
    elseif ($raw -match [regex]::Escape($textureName)) {
        Fail "texture is referenced with a nonstandard path: $textureName"
    }
}

if ($referencedTextures -lt 6) {
    Fail "only $referencedTextures of $($textureNames.Count) expected greenhouse textures use the normalized path"
}
elseif ($referencedTextures -lt $textureNames.Count) {
    Warn "$referencedTextures of $($textureNames.Count) expected textures are referenced; inspect merged or omitted materials in GIANTS Editor"
}
else {
    Pass "all expected greenhouse texture names use ../textures/<filename>"
}

if ($raw -match '\$data/') {
    Warn "The i3d contains one or more game-data references. Confirm they are intentional shader references."
}

Write-Host ""
Write-Host "Export repair and validation summary" -ForegroundColor Cyan
Write-Host "Failures: $($failures.Count)"
Write-Host "Warnings: $($warnings.Count)"

if ($failures.Count -gt 0) {
    Write-Host "The package/install step must stay blocked until these failures are fixed." -ForegroundColor Red
    exit 1
}

Write-Host "Greenhouse export is ready for GIANTS Editor, XML preflight, and packaging." -ForegroundColor Green
exit 0
