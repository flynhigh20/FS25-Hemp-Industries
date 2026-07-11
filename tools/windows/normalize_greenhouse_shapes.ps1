param(
    [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"

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

$root = Find-RepoRoot
$i3dFolder = Join-Path $root "FS25_GreenHorizonIndustries\placeables\greenhouses\i3d"
$i3dPath = Join-Path $i3dFolder "greenHorizonHempGreenhouse.i3d"
$canonicalName = "greenHorizonHempGreenhouse.i3d.shapes"
$canonicalPath = Join-Path $i3dFolder $canonicalName

if (-not (Test-Path $i3dPath)) {
    throw "Greenhouse i3d was not found: $i3dPath"
}

$encoding = [System.Text.Encoding]::GetEncoding(28591)
$raw = [System.IO.File]::ReadAllText($i3dPath, $encoding)

$shapeFiles = @(Get-ChildItem -Path $i3dFolder -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '(?i)^greenhorizonhempgreenhouse\.i3d\.shapes$' })

if ($shapeFiles.Count -eq 0) {
    throw "No greenhouse .i3d.shapes file was found beside the i3d."
}

$source = $shapeFiles | Select-Object -First 1
if ($source.Name -cne $canonicalName) {
    $temporaryPath = Join-Path $i3dFolder "greenhouse_shapes_casefix.tmp"
    if (Test-Path $temporaryPath) {
        Remove-Item $temporaryPath -Force
    }

    Move-Item -LiteralPath $source.FullName -Destination $temporaryPath -Force
    Move-Item -LiteralPath $temporaryPath -Destination $canonicalPath -Force
    Write-Host "Renamed shapes file to exact canonical case: $canonicalName" -ForegroundColor Green
}
else {
    Write-Host "Shapes filename already uses exact canonical case." -ForegroundColor Green
}

$shapePattern = 'externalShapesFile="[^"]+"'
$replacement = 'externalShapesFile="' + $canonicalName + '"'

if ($raw -notmatch $shapePattern) {
    throw "The i3d does not contain an externalShapesFile attribute."
}

$normalized = [regex]::Replace($raw, $shapePattern, $replacement, 1)
if ($normalized -ne $raw) {
    $backupPath = "$i3dPath.shapefix.bak"
    [System.IO.File]::WriteAllText($backupPath, $raw, $encoding)
    [System.IO.File]::WriteAllText($i3dPath, $normalized, $encoding)
    Write-Host "Normalized i3d shapes reference to: $canonicalName" -ForegroundColor Green
    Write-Host "Backup: $backupPath"
}
else {
    Write-Host "I3d shapes reference already matches canonical filename." -ForegroundColor Green
}

if (-not (Test-Path $canonicalPath)) {
    throw "Canonical shapes file still does not exist after normalization: $canonicalPath"
}

Write-Host "Greenhouse shapes file and i3d reference now match exactly." -ForegroundColor Green
exit 0
