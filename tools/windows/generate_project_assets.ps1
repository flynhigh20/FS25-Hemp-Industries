param(
    [ValidateSet("greenhouse", "field", "pallets", "all")]
    [string]$Target = "all",
    [string]$BlenderExe = "",
    [switch]$OpenOutputFolders
)

$ErrorActionPreference = "Stop"
$failures = New-Object System.Collections.Generic.List[string]

function Find-RepoRoot {
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

function Resolve-BlenderExecutable {
    param([string]$RequestedPath)

    if (-not [string]::IsNullOrWhiteSpace($RequestedPath)) {
        if (Test-Path $RequestedPath) {
            return (Resolve-Path $RequestedPath).Path
        }
        throw "The requested Blender executable does not exist: $RequestedPath"
    }

    $command = Get-Command blender.exe -ErrorAction SilentlyContinue
    if ($null -ne $command) {
        return $command.Source
    }

    $preferred = @(
        (Join-Path $env:ProgramFiles "Blender Foundation\Blender 4.2\blender.exe"),
        (Join-Path ${env:ProgramFiles(x86)} "Blender Foundation\Blender 4.2\blender.exe"),
        (Join-Path $env:LOCALAPPDATA "Programs\Blender Foundation\Blender 4.2\blender.exe")
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    foreach ($candidate in $preferred) {
        if (Test-Path $candidate) {
            return (Resolve-Path $candidate).Path
        }
    }

    $searchRoots = @(
        (Join-Path $env:ProgramFiles "Blender Foundation"),
        (Join-Path ${env:ProgramFiles(x86)} "Blender Foundation"),
        (Join-Path $env:LOCALAPPDATA "Programs\Blender Foundation")
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path $_) }

    $matches = New-Object System.Collections.Generic.List[object]
    foreach ($searchRoot in $searchRoots) {
        Get-ChildItem -Path $searchRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "Blender *" } |
            ForEach-Object {
                $candidate = Join-Path $_.FullName "blender.exe"
                if (Test-Path $candidate) {
                    $matches.Add((Get-Item $candidate)) | Out-Null
                }
            }
    }

    $best = $matches | Sort-Object FullName -Descending | Select-Object -First 1
    if ($null -ne $best) {
        return $best.FullName
    }

    throw @"
Blender was not found automatically.
Install Blender 4.2 LTS or run this script with:
  -BlenderExe "C:\Program Files\Blender Foundation\Blender 4.2\blender.exe"
"@
}

function Test-ExpectedOutputs {
    param(
        [string]$RepoRoot,
        [string[]]$RelativePaths,
        [string]$StepName
    )

    $missing = New-Object System.Collections.Generic.List[string]
    foreach ($relativePath in $RelativePaths) {
        $fullPath = Join-Path $RepoRoot ($relativePath.Replace("/", "\"))
        if (-not (Test-Path $fullPath)) {
            $missing.Add($relativePath) | Out-Null
            continue
        }

        $item = Get-Item $fullPath
        if (-not $item.PSIsContainer -and $item.Length -le 0) {
            $missing.Add("$relativePath (empty)") | Out-Null
        }
    }

    if ($missing.Count -gt 0) {
        foreach ($entry in $missing) {
            Write-Host "MISSING: $entry" -ForegroundColor Red
        }
        throw "$StepName did not produce all expected outputs."
    }

    Write-Host "PASS: $StepName produced $($RelativePaths.Count) expected files." -ForegroundColor Green
}

function Invoke-BlenderGenerator {
    param(
        [string]$Name,
        [string]$ScriptRelativePath,
        [string[]]$ExpectedOutputs,
        [string]$BlenderPath,
        [string]$RepoRoot,
        [string]$LogDirectory
    )

    $scriptPath = Join-Path $RepoRoot ($ScriptRelativePath.Replace("/", "\"))
    if (-not (Test-Path $scriptPath)) {
        throw "Missing Blender generator: $ScriptRelativePath"
    }

    $safeName = $Name.ToLowerInvariant().Replace(" ", "_")
    $logPath = Join-Path $LogDirectory ("$safeName.log")

    Write-Host "" 
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "Running: $Name" -ForegroundColor Cyan
    Write-Host "Script:  $ScriptRelativePath"
    Write-Host "Log:     $logPath"
    Write-Host "==================================================" -ForegroundColor Cyan

    Push-Location $RepoRoot
    try {
        & $BlenderPath --background --factory-startup --python $scriptPath 2>&1 |
            Tee-Object -FilePath $logPath
        $exitCode = $LASTEXITCODE
    }
    finally {
        Pop-Location
    }

    if ($exitCode -ne 0) {
        throw "$Name failed with Blender exit code $exitCode. Check $logPath"
    }

    Test-ExpectedOutputs -RepoRoot $RepoRoot -RelativePaths $ExpectedOutputs -StepName $Name
}

$repoRoot = Find-RepoRoot
$blenderPath = Resolve-BlenderExecutable -RequestedPath $BlenderExe
$logsDir = Join-Path $repoRoot "build\logs\blender"
New-Item -ItemType Directory -Force -Path $logsDir | Out-Null

$versionLine = (& $blenderPath --version 2>&1 | Select-Object -First 1)
Write-Host "Green Horizon Industries - Asset Generation" -ForegroundColor Green
Write-Host "Target:  $Target"
Write-Host "Repo:    $repoRoot"
Write-Host "Blender: $blenderPath"
Write-Host "Version: $versionLine"

if ($versionLine -notmatch "4\.2") {
    Write-Host "WARN: Blender 4.2 LTS is the tested target. Continuing with the detected version." -ForegroundColor Yellow
}

$greenhouseOutputs = @(
    "assets/blender/green_horizon_hemp_greenhouse.blend",
    "FS25_GreenHorizonIndustries/placeables/greenhouses/textures/greenhouse_glass_diffuse.png",
    "FS25_GreenHorizonIndustries/placeables/greenhouses/textures/greenhouse_frame_diffuse.png",
    "FS25_GreenHorizonIndustries/placeables/greenhouses/textures/greenhouse_concrete_diffuse.png",
    "FS25_GreenHorizonIndustries/placeables/greenhouses/textures/greenhouse_soil_diffuse.png",
    "FS25_GreenHorizonIndustries/placeables/greenhouses/textures/greenhouse_hemp_leaf_diffuse.png",
    "FS25_GreenHorizonIndustries/placeables/greenhouses/textures/greenhouse_stem_diffuse.png",
    "FS25_GreenHorizonIndustries/placeables/greenhouses/textures/greenhouse_water_tank_diffuse.png",
    "FS25_GreenHorizonIndustries/placeables/greenhouses/textures/greenhouse_rubber_diffuse.png",
    "FS25_GreenHorizonIndustries/placeables/greenhouses/textures/greenhouse_wire_diffuse.png",
    "FS25_GreenHorizonIndustries/placeables/greenhouses/textures/greenhouse_light_diffuse.png"
)

$foliageOutputs = @(
    "assets/blender/green_horizon_hemp_foliage.blend",
    "FS25_GreenHorizonIndustries/foliage/hemp/textures/hempFoliage_diffuse.png",
    "FS25_GreenHorizonIndustries/foliage/hemp/textures/hempFoliage_normal.png",
    "FS25_GreenHorizonIndustries/foliage/hemp/textures/hempFoliage_distance_diffuse.png",
    "FS25_GreenHorizonIndustries/foliage/hemp/textures/hempFoliage_distance_normal.png"
)

$iconOutputs = @(
    "FS25_GreenHorizonIndustries/ui/icons/fillType_hemp.png",
    "FS25_GreenHorizonIndustries/ui/icons/fillType_hempSeed.png",
    "FS25_GreenHorizonIndustries/ui/icons/fillType_hempBiomass.png",
    "FS25_GreenHorizonIndustries/ui/icons/fillType_hempFiber.png",
    "FS25_GreenHorizonIndustries/ui/icons/fillType_hempFlower.png",
    "FS25_GreenHorizonIndustries/ui/icons/fillType_hempOil.png",
    "FS25_GreenHorizonIndustries/ui/icons/crop_hemp.png",
    "FS25_GreenHorizonIndustries/ui/icons/calendar_hemp.png"
)

$cutterOutputs = @(
    "assets/blender/green_horizon_hemp_cutter_effects.blend",
    "FS25_GreenHorizonIndustries/foliage/hemp/effects/textures/hemp_chaff_diffuse.png",
    "FS25_GreenHorizonIndustries/foliage/hemp/effects/textures/hemp_stem_shard_diffuse.png",
    "FS25_GreenHorizonIndustries/foliage/hemp/effects/textures/hemp_leaf_fragment_diffuse.png",
    "FS25_GreenHorizonIndustries/foliage/hemp/effects/textures/hemp_dust_diffuse.png"
)

$palletOutputs = @(
    "assets/blender/green_horizon_product_pallets.blend",
    "FS25_GreenHorizonIndustries/pallets/textures/pallet_wood_diffuse.png",
    "FS25_GreenHorizonIndustries/pallets/textures/pallet_dark_wood_diffuse.png",
    "FS25_GreenHorizonIndustries/pallets/textures/pallet_wrap_diffuse.png",
    "FS25_GreenHorizonIndustries/pallets/textures/pallet_label_diffuse.png",
    "FS25_GreenHorizonIndustries/pallets/textures/pallet_hemp_diffuse.png",
    "FS25_GreenHorizonIndustries/pallets/textures/pallet_seed_diffuse.png",
    "FS25_GreenHorizonIndustries/pallets/textures/pallet_biomass_diffuse.png",
    "FS25_GreenHorizonIndustries/pallets/textures/pallet_fiber_diffuse.png",
    "FS25_GreenHorizonIndustries/pallets/textures/pallet_flower_diffuse.png",
    "FS25_GreenHorizonIndustries/pallets/textures/pallet_oil_diffuse.png"
)

$steps = New-Object System.Collections.Generic.List[hashtable]

if ($Target -in @("greenhouse", "all")) {
    $steps.Add(@{
        Name = "Greenhouse Model and Materials"
        Script = "tools/blender/create_green_horizon_greenhouse.py"
        Outputs = $greenhouseOutputs
    }) | Out-Null
}

if ($Target -in @("field", "all")) {
    $steps.Add(@{
        Name = "Hemp Foliage States"
        Script = "tools/blender/create_hemp_foliage.py"
        Outputs = $foliageOutputs
    }) | Out-Null
    $steps.Add(@{
        Name = "Hemp Crop and Product Icons"
        Script = "tools/blender/create_hemp_crop_icons.py"
        Outputs = $iconOutputs
    }) | Out-Null
    $steps.Add(@{
        Name = "Hemp Cutter Effect Sources"
        Script = "tools/blender/create_hemp_cutter_effects.py"
        Outputs = $cutterOutputs
    }) | Out-Null
}

if ($Target -in @("pallets", "all")) {
    $steps.Add(@{
        Name = "Green Horizon Product Pallets"
        Script = "tools/blender/create_green_horizon_pallets.py"
        Outputs = $palletOutputs
    }) | Out-Null
}

foreach ($step in $steps) {
    try {
        Invoke-BlenderGenerator \
            -Name $step.Name \
            -ScriptRelativePath $step.Script \
            -ExpectedOutputs $step.Outputs \
            -BlenderPath $blenderPath \
            -RepoRoot $repoRoot \
            -LogDirectory $logsDir
    }
    catch {
        $failures.Add("$($step.Name): $($_.Exception.Message)") | Out-Null
        Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
        break
    }
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Asset generation summary" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Host "FAIL: $failure" -ForegroundColor Red
    }
    Write-Host "Logs: $logsDir" -ForegroundColor Yellow
    exit 1
}

Write-Host "All selected generators completed successfully." -ForegroundColor Green
Write-Host "Logs: $logsDir"

if ($Target -in @("greenhouse", "all")) {
    Write-Host ""
    Write-Host "MANUAL GREENHOUSE EXPORT STILL REQUIRED:" -ForegroundColor Yellow
    Write-Host "1. Open assets/blender/green_horizon_hemp_greenhouse.blend"
    Write-Host "2. Export root greenHorizonHempGreenhouse"
    Write-Host "3. Save to FS25_GreenHorizonIndustries/placeables/greenhouses/i3d/greenHorizonHempGreenhouse.i3d"
    Write-Host "4. Relative paths: Yes. Game paths: No."
    Write-Host "5. Open and save the i3d in GIANTS Editor."
    Write-Host "6. Run tools/windows/validate_greenhouse_export.bat"
}

if ($OpenOutputFolders) {
    Start-Process explorer.exe (Join-Path $repoRoot "assets\blender")
    Start-Process explorer.exe (Join-Path $repoRoot "FS25_GreenHorizonIndustries")
}

exit 0
