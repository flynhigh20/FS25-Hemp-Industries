param(
    [string]$LogPath = "$env:USERPROFILE\Documents\My Games\FarmingSimulator2025\log.txt",
    [string]$ModName = "FS25_GreenHorizonIndustries"
)

$ErrorActionPreference = "Stop"

$patterns = @(
    $ModName,
    "Version:",
    "Loaded 3 fill types from mod",
    "placeables/greenhouses/hempGreenhouse.xml",
    "storeItem_ghi_hempGreenhouse",
    "production_ghi_hempGreenhouseBasic",
    "Hemp Greenhouse",
    "Invalid store item",
    "Invalid placeable",
    "Unknown category",
    "Invalid category",
    "No categories defined",
    "Can't load resource",
    "Error:",
    "Warning"
)

Write-Host "Green Horizon Industries - FS25 Log Checker" -ForegroundColor Green
Write-Host "Log path: $LogPath"
Write-Host ""

if (-not (Test-Path $LogPath)) {
    Write-Host "Could not find FS25 log file." -ForegroundColor Red
    Write-Host "Start FS25 once, close it, then run this checker again."
    exit 1
}

$lines = Get-Content -Path $LogPath
$matches = New-Object System.Collections.Generic.List[string]

for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    foreach ($pattern in $patterns) {
        if ($line -like "*$pattern*") {
            $lineNumber = $i + 1
            $matches.Add(("{0,6}: {1}" -f $lineNumber, $line))
            break
        }
    }
}

if ($matches.Count -eq 0) {
    Write-Host "No matching Green Horizon / warning / error lines found." -ForegroundColor Yellow
    Write-Host "That can mean the mod did not load, the log path is wrong, or FS25 has not been run since installing the mod."
    exit 0
}

Write-Host "Found $($matches.Count) matching lines:" -ForegroundColor Cyan
Write-Host ""
$matches | ForEach-Object { Write-Host $_ }

$reportDir = Join-Path (Split-Path -Parent $LogPath) "GreenHorizonReports"
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$reportPath = Join-Path $reportDir "green_horizon_log_report_$timestamp.txt"

@(
    "Green Horizon Industries FS25 Log Report",
    "Created: $(Get-Date)",
    "Log path: $LogPath",
    "",
    "Matching lines:",
    ""
) + $matches | Set-Content -Path $reportPath -Encoding UTF8

Write-Host ""
Write-Host "Saved report:" -ForegroundColor Green
Write-Host $reportPath
Write-Host ""
Write-Host "If the greenhouse is missing, send this report text for debugging." -ForegroundColor Green
