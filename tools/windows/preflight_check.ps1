param(
    [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"
$expectedVersion = "0.2.6.0"
$expectedStoreCategory = "productionPoints"
$expectedIconFilename = "icon_mod.dds"
$failures = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

function Find-RepoRoot {
    if (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
        return (Resolve-Path $RepoRoot).Path
    }

    $scriptDir = Split-Path -Parent $PSCommandPath
    $current = Resolve-Path $scriptDir

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

    throw "Could not find repo root. Run this from inside the FS25-Hemp-Industries repo."
}

function Add-Failure([string]$message) {
    $failures.Add($message) | Out-Null
    Write-Host "FAIL: $message" -ForegroundColor Red
}

function Add-Warning([string]$message) {
    $warnings.Add($message) | Out-Null
    Write-Host "WARN: $message" -ForegroundColor Yellow
}

function Add-Pass([string]$message) {
    Write-Host "PASS: $message" -ForegroundColor Green
}

function Read-XmlFile([string]$path) {
    try {
        [xml](Get-Content -Path $path -Raw)
    }
    catch {
        Add-Failure "XML parse failed: $path -- $($_.Exception.Message)"
        return $null
    }
}

function Test-ZipRoot([string]$zipPath) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    try {
        foreach ($entry in $zip.Entries) {
            if ($entry.FullName -eq "modDesc.xml") {
                return $true
            }
        }
        return $false
    }
    finally {
        $zip.Dispose()
    }
}

function Test-ZipEntry([string]$zipPath, [string]$entryName) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    try {
        foreach ($entry in $zip.Entries) {
            if ($entry.FullName -eq $entryName) {
                return $true
            }
        }
        return $false
    }
    finally {
        $zip.Dispose()
    }
}

$root = Find-RepoRoot
$modFolder = Join-Path $root "FS25_GreenHorizonIndustries"
$modDescPath = Join-Path $modFolder "modDesc.xml"
$greenhouseXmlPath = Join-Path $modFolder "placeables\greenhouses\hempGreenhouse.xml"
$fillTypesPath = Join-Path $modFolder "xml\fillTypes.xml"
$iconPath = Join-Path $modFolder $expectedIconFilename
$distZipPath = Join-Path $root "dist\FS25_GreenHorizonIndustries.zip"

Write-Host "Green Horizon Industries - Preflight Check" -ForegroundColor Cyan
Write-Host "Repo: $root"
Write-Host "Expected mod version: $expectedVersion"
Write-Host "Expected store category: $expectedStoreCategory"
Write-Host "Expected icon: $expectedIconFilename"
Write-Host ""

if (Test-Path $modFolder) { Add-Pass "Mod folder exists: FS25_GreenHorizonIndustries" } else { Add-Failure "Missing mod folder: FS25_GreenHorizonIndustries" }
if (Test-Path $modDescPath) { Add-Pass "modDesc.xml exists at mod root" } else { Add-Failure "Missing modDesc.xml at mod root" }
if (Test-Path $greenhouseXmlPath) { Add-Pass "Hemp greenhouse XML exists" } else { Add-Failure "Missing hempGreenhouse.xml" }
if (Test-Path $fillTypesPath) { Add-Pass "fillTypes.xml exists" } else { Add-Failure "Missing fillTypes.xml" }

$modDesc = $null
if (Test-Path $modDescPath) {
    $modDesc = Read-XmlFile $modDescPath
}

if ($null -ne $modDesc) {
    $descVersion = $modDesc.modDesc.descVersion
    $version = $modDesc.modDesc.version
    $iconFilename = $modDesc.modDesc.iconFilename

    if ($descVersion -eq "91") { Add-Pass "modDesc descVersion is 91" } else { Add-Warning "modDesc descVersion is '$descVersion' instead of current local test value 91" }
    if ($version -eq $expectedVersion) { Add-Pass "mod version is $expectedVersion" } else { Add-Warning "mod version is '$version' instead of expected $expectedVersion" }

    if ($iconFilename -eq $expectedIconFilename) {
        Add-Pass "modDesc iconFilename is $expectedIconFilename"
    }
    else {
        Add-Failure "modDesc iconFilename is '$iconFilename' instead of $expectedIconFilename"
    }

    if (Test-Path $iconPath) {
        Add-Pass "icon file exists: $expectedIconFilename"
    }
    else {
        Add-Warning "icon file not found yet: $expectedIconFilename. Run package_and_install_mod.bat to generate the alpha placeholder icon."
    }

    $storeItems = $modDesc.modDesc.storeItems.storeItem
    if ($null -eq $storeItems) {
        Add-Failure "No storeItems/storeItem entries found in modDesc.xml"
    }
    else {
        foreach ($item in @($storeItems)) {
            $xmlFilename = $item.xmlFilename
            if ([string]::IsNullOrWhiteSpace($xmlFilename)) {
                Add-Failure "storeItem missing xmlFilename"
                continue
            }
            $target = Join-Path $modFolder ($xmlFilename -replace '/', '\')
            if (Test-Path $target) { Add-Pass "storeItem target exists: $xmlFilename" } else { Add-Failure "storeItem target missing: $xmlFilename" }
        }
    }

    $fillTypesFilename = $modDesc.modDesc.fillTypes.filename
    if ([string]::IsNullOrWhiteSpace($fillTypesFilename)) {
        Add-Failure "modDesc.xml missing fillTypes filename"
    }
    else {
        $target = Join-Path $modFolder ($fillTypesFilename -replace '/', '\')
        if (Test-Path $target) { Add-Pass "fillTypes target exists: $fillTypesFilename" } else { Add-Failure "fillTypes target missing: $fillTypesFilename" }
    }
}

$greenhouseXml = $null
if (Test-Path $greenhouseXmlPath) {
    $greenhouseXml = Read-XmlFile $greenhouseXmlPath
}

if ($null -ne $greenhouseXml) {
    $categoryNodes = Select-Xml -Xml $greenhouseXml -XPath "//*[local-name()='category']"
    if ($categoryNodes.Count -eq 0) {
        Add-Failure "No <category> tag found in hempGreenhouse.xml"
    }
    else {
        $categoryValues = @($categoryNodes | ForEach-Object { $_.Node.InnerText.Trim() })
        if ($categoryValues -contains $expectedStoreCategory) { Add-Pass "greenhouse category includes $expectedStoreCategory" } else { Add-Warning "greenhouse category is '$($categoryValues -join ', ')' instead of $expectedStoreCategory" }
        if ($categoryValues -contains "greenhouses") { Add-Warning "greenhouse category is greenhouses; verify against FS25 schema/log because an earlier local test rejected it" }
    }

    $allText = Get-Content -Path $greenhouseXmlPath -Raw
    foreach ($needle in @("storeItem_ghi_hempGreenhouse", "production_ghi_hempGreenhouseBasic", "GHI_HEMP_SEED", "GHI_HEMP_BIOMASS")) {
        if ($allText -like "*$needle*") { Add-Pass "greenhouse XML contains $needle" } else { Add-Warning "greenhouse XML missing expected text: $needle" }
    }
}

if (Test-Path $distZipPath) {
    if (Test-ZipRoot $distZipPath) { Add-Pass "dist zip root is correct: modDesc.xml is at top" } else { Add-Failure "dist zip root is wrong: modDesc.xml is not at top" }
    if (Test-ZipEntry $distZipPath $expectedIconFilename) { Add-Pass "dist zip contains $expectedIconFilename" } else { Add-Warning "dist zip missing $expectedIconFilename. Re-run package_and_install_mod.bat." }
}
else {
    Add-Warning "No dist zip found yet. Run package_mod.bat or package_and_install_mod.bat."
}

Write-Host ""
Write-Host "Preflight summary" -ForegroundColor Cyan
Write-Host "Failures: $($failures.Count)"
Write-Host "Warnings: $($warnings.Count)"

if ($failures.Count -gt 0) {
    Write-Host ""
    Write-Host "Fix failures before testing in FS25." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Preflight passed. Warnings may still be okay for an alpha test." -ForegroundColor Green
exit 0
