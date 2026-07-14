param(
    [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

$modFolder = Join-Path $RepoRoot "FS25_GreenHorizonIndustries"
$palletFolder = Join-Path $modFolder "pallets\i3d"
$greenhouseI3d = Join-Path $modFolder "placeables\greenhouses\i3d\greenHorizonHempGreenhouse.i3d"

$pallets = @(
    @{ File = "hempPallet.i3d"; Root = "pallet_hemp" },
    @{ File = "flowerPallet.i3d"; Root = "pallet_flower" },
    @{ File = "biomassPallet.i3d"; Root = "pallet_biomass" }
)

function Set-BlackEmissiveDefaults {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Missing I3D: $Path"
    }

    $text = Get-Content -LiteralPath $Path -Raw
    $updated = $text.Replace('emissiveColor="1 1 1 1"', 'emissiveColor="0 0 0 1"')
    if ($updated -ne $text) {
        [System.IO.File]::WriteAllText($Path, $updated, [System.Text.UTF8Encoding]::new($false))
        Write-Host "PASS: Disabled unintended white emissive defaults in $Path"
    }
    else {
        Write-Host "PASS: Emissive defaults already safe in $Path"
    }
}

function Repair-PalletI3d {
    param(
        [string]$Path,
        [string]$RootName
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Missing pallet I3D: $Path"
    }

    $text = Get-Content -LiteralPath $Path -Raw
    $text = $text.Replace('emissiveColor="1 1 1 1"', 'emissiveColor="0 0 0 1"')

    $rootPattern = '<TransformGroup name="' + [regex]::Escape($RootName) + '" nodeId="(?<nodeId>\d+)">'
    $rootReplacement = '<Shape name="' + $RootName + '" shapeId="1" dynamic="true" compound="true" staticFriction="1" dynamicFriction="1" density="0" collisionFilterGroup="0x10004" collisionFilterMask="0xfe3ffb83" nodeId="${nodeId}" castsShadows="false" receiveShadows="false" nonRenderable="true" materialIds="1" clipDistance="150">'
    $text = [regex]::Replace($text, $rootPattern, $rootReplacement, 1)

    $text = [regex]::Replace(
        $text,
        '(<Shape name="floorCollision0[12](?:\.\d+)?"[^>]*?shapeId="\d+")(?=\s+nodeId=)',
        '$1 compoundChild="true" staticFriction="1" dynamicFriction="1" density="0" collisionFilterGroup="0x10000" collisionFilterMask="0xfe3dfb83" nonRenderable="true"'
    )

    $text = [regex]::Replace(
        $text,
        '(<Shape name="' + [regex]::Escape($RootName) + '"[^>]*?)collisionFilterGroup="0x10000" collisionFilterMask="0x1813008" density="0.1"([^>]*>)',
        '$1staticFriction="1" dynamicFriction="1" density="0" collisionFilterGroup="0x10004" collisionFilterMask="0xfe3ffb83"$2'
    )
    $text = $text.Replace('compoundChild="true" collisionFilterGroup="0x10000" collisionFilterMask="0x1813008" density="0.1" nonRenderable="true"', 'compoundChild="true" staticFriction="1" dynamicFriction="1" density="0" collisionFilterGroup="0x10000" collisionFilterMask="0xfe3dfb83" nonRenderable="true"')
    $text = $text.Replace('collisionFilterMask="0x2000" nonRenderable="true"', 'collisionFilterMask="0x20000" nonRenderable="true"')

    $text = [regex]::Replace(
        $text,
        '(<Shape name="dynamicMountTrigger(?:\.\d+)?"[^>]*?shapeId="\d+")(?=\s+nodeId=)',
        '$1 kinematic="true" trigger="true" collisionFilterGroup="0x20000000" collisionFilterMask="0x2000" nonRenderable="true"'
    )

    $text = [regex]::Replace(
        $text,
        '(\r?\n\s*)</TransformGroup>(\r?\n\s*</Scene>)',
        '$1</Shape>$2',
        1
    )

    if ($text -notmatch ('<Shape name="' + [regex]::Escape($RootName) + '"[^>]*dynamic="true"[^>]*compound="true"')) {
        throw "Dynamic pallet root repair failed for $RootName"
    }
    if ($text -notmatch 'dynamicMountTrigger[^>]*trigger="true"') {
        throw "Dynamic mount trigger repair failed for $RootName"
    }

    [System.IO.File]::WriteAllText($Path, $text, [System.Text.UTF8Encoding]::new($false))
    [xml](Get-Content -LiteralPath $Path -Raw) | Out-Null
    Write-Host "PASS: Repaired movable pallet physics in $Path"
}

foreach ($pallet in $pallets) {
    Repair-PalletI3d -Path (Join-Path $palletFolder $pallet.File) -RootName $pallet.Root
}

Set-BlackEmissiveDefaults -Path $greenhouseI3d

Write-Host "Custom pallet physics and material repair completed."
exit 0
