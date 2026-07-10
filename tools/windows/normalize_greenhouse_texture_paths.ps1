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
$i3dPath = Join-Path $root "FS25_GreenHorizonIndustries\placeables\greenhouses\i3d\greenHorizonHempGreenhouse.i3d"
$textureFolder = Join-Path $root "FS25_GreenHorizonIndustries\placeables\greenhouses\textures"

if (-not (Test-Path $i3dPath)) {
    throw "Greenhouse i3d was not found: $i3dPath"
}

$encoding = [System.Text.Encoding]::GetEncoding(28591)
$raw = [System.IO.File]::ReadAllText($i3dPath, $encoding)

$texturePattern = 'filename="[^"]*(greenhouse_(?:glass|frame|concrete|soil|hemp_leaf|stem|water_tank|rubber|wire|light)_diffuse\.png)"'
$matches = [regex]::Matches($raw, $texturePattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

if ($matches.Count -eq 0) {
    Write-Host "No greenhouse texture filename entries were found to normalize." -ForegroundColor Yellow
    exit 0
}

$replacementEvaluator = [System.Text.RegularExpressions.MatchEvaluator]{
    param($match)
    return 'filename="../textures/' + $match.Groups[1].Value + '"'
}

$normalized = [regex]::Replace(
    $raw,
    $texturePattern,
    $replacementEvaluator,
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
)

if ($normalized -ne $raw) {
    $backupPath = "$i3dPath.pathfix.bak"
    [System.IO.File]::WriteAllText($backupPath, $raw, $encoding)
    [System.IO.File]::WriteAllText($i3dPath, $normalized, $encoding)
    Write-Host "Normalized $($matches.Count) greenhouse texture path entries." -ForegroundColor Green
    Write-Host "Backup: $backupPath"
}
else {
    Write-Host "Greenhouse texture paths were already normalized." -ForegroundColor Green
}

$missingTextures = New-Object System.Collections.Generic.List[string]
$normalizedMatches = [regex]::Matches($normalized, 'filename="\.\./textures/([^"]+)"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
foreach ($match in $normalizedMatches) {
    $filename = $match.Groups[1].Value
    $fullPath = Join-Path $textureFolder $filename
    if (-not (Test-Path $fullPath)) {
        $missingTextures.Add($filename) | Out-Null
    }
}

if ($missingTextures.Count -gt 0) {
    foreach ($filename in $missingTextures) {
        Write-Host "MISSING TEXTURE: $filename" -ForegroundColor Red
    }
    exit 1
}

Write-Host "All normalized greenhouse texture files exist beside the i3d texture folder." -ForegroundColor Green
exit 0
