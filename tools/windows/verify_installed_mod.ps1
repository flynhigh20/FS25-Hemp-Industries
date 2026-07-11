param(
    [string]$ModsDir = "$env:USERPROFILE\Documents\My Games\FarmingSimulator2025\mods"
)

$ErrorActionPreference = "Stop"

$zipPath = Join-Path $ModsDir "FS25_GreenHorizonIndustries.zip"
$loosePath = Join-Path $ModsDir "FS25_GreenHorizonIndustries"

Write-Host "Green Horizon Industries - Installed Mod Check" -ForegroundColor Cyan
Write-Host "Mods folder: $ModsDir"
Write-Host ""

if (Test-Path $loosePath) {
    throw "Conflicting loose mod folder still exists: $loosePath"
}

if (-not (Test-Path $zipPath)) {
    throw "Installed ZIP was not found: $zipPath"
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
try {
    $entries = @{}
    foreach ($entry in $zip.Entries) {
        $entries[$entry.FullName.Replace("\", "/")] = $entry.Length
    }

    $required = @(
        "modDesc.xml",
        "xml/fillTypes.xml",
        "placeables/greenhouses/hempGreenhouse.xml",
        "placeables/greenhouses/i3d/greenHorizonHempGreenhouse.i3d",
        "placeables/greenhouses/i3d/greenHorizonHempGreenhouse.i3d.shapes"
    )

    foreach ($relativePath in $required) {
        if (-not $entries.ContainsKey($relativePath)) {
            throw "Installed ZIP is missing: $relativePath"
        }
        if ($entries[$relativePath] -le 0) {
            throw "Installed ZIP contains an empty file: $relativePath"
        }
        Write-Host "PASS: $relativePath" -ForegroundColor Green
    }

    if ($entries.ContainsKey("FS25_GreenHorizonIndustries/modDesc.xml")) {
        throw "Installed ZIP has an extra FS25_GreenHorizonIndustries wrapper folder. modDesc.xml must be at ZIP root."
    }
}
finally {
    $zip.Dispose()
}

Write-Host ""
Write-Host "Installed ZIP structure is complete and conflict-free." -ForegroundColor Green
exit 0
