param(
    [switch]$Install,
    [switch]$InstallLoose,
    [switch]$CleanOldZips,
    [string]$ModsDir = "$env:USERPROFILE\Documents\My Games\FarmingSimulator2025\mods"
)

$ErrorActionPreference = "Stop"

function Find-RepoRoot {
    $scriptDir = Split-Path -Parent $PSCommandPath
    $current = Resolve-Path $scriptDir

    while ($null -ne $current) {
        $candidate = Join-Path $current "FS25_GreenHorizonIndustries\modDesc.xml"
        if (Test-Path $candidate) {
            return $current.Path
        }

        $parent = Split-Path -Parent $current
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $current.Path) {
            break
        }
        $current = Resolve-Path $parent
    }

    throw "Could not find repo root. Run this script from inside the FS25-Hemp-Industries repo."
}

function Get-ModVersion {
    param([string]$ModDescPath)

    [xml]$modDesc = Get-Content -Path $ModDescPath -Raw
    return $modDesc.modDesc.version.Trim()
}

function Write-UInt32LE {
    param(
        [byte[]]$Buffer,
        [int]$Offset,
        [UInt32]$Value
    )

    $bytes = [BitConverter]::GetBytes($Value)
    [Array]::Copy($bytes, 0, $Buffer, $Offset, 4)
}

function New-PlaceholderDdsIcon {
    param([string]$IconPath)

    # Minimal uncompressed 256x256 A8R8G8B8 DDS placeholder.
    # This is only for alpha testing. Replace with a real GIANTS-generated icon_mod.dds later.
    $width = 256
    $height = 256
    $headerSize = 128
    $bytesPerPixel = 4
    $dataSize = $width * $height * $bytesPerPixel
    $buffer = New-Object byte[] ($headerSize + $dataSize)

    $buffer[0] = [byte][char]'D'
    $buffer[1] = [byte][char]'D'
    $buffer[2] = [byte][char]'S'
    $buffer[3] = 32

    Write-UInt32LE $buffer 4 124
    Write-UInt32LE $buffer 8 0x0000100F
    Write-UInt32LE $buffer 12 $height
    Write-UInt32LE $buffer 16 $width
    Write-UInt32LE $buffer 20 ($width * 4)

    Write-UInt32LE $buffer 76 32
    Write-UInt32LE $buffer 80 0x00000041
    Write-UInt32LE $buffer 88 32
    Write-UInt32LE $buffer 92 0x00FF0000
    Write-UInt32LE $buffer 96 0x0000FF00
    Write-UInt32LE $buffer 100 0x000000FF
    Write-UInt32LE $buffer 104 0xFF000000
    Write-UInt32LE $buffer 108 0x00001000

    for ($y = 0; $y -lt $height; $y++) {
        for ($x = 0; $x -lt $width; $x++) {
            $offset = $headerSize + (($y * $width + $x) * $bytesPerPixel)
            $border = ($x -lt 10 -or $x -gt ($width - 11) -or $y -lt 10 -or $y -gt ($height - 11))
            $center = ($x -gt 72 -and $x -lt 184 -and $y -gt 72 -and $y -lt 184)
            $stripe = ([Math]::Abs($x - $y) -lt 10)

            if ($border) {
                $r = 26; $g = 82; $b = 38
            }
            elseif ($center -or $stripe) {
                $r = 74; $g = 168; $b = 84
            }
            else {
                $r = 12; $g = 42; $b = 24
            }

            $buffer[$offset + 0] = [byte]$b
            $buffer[$offset + 1] = [byte]$g
            $buffer[$offset + 2] = [byte]$r
            $buffer[$offset + 3] = 255
        }
    }

    [System.IO.File]::WriteAllBytes($IconPath, $buffer)
}

function New-PlaceholderStorePng {
    param([string]$ImagePath)

    Add-Type -AssemblyName System.Drawing

    $dir = Split-Path -Parent $ImagePath
    New-Item -ItemType Directory -Force -Path $dir | Out-Null

    $bitmap = New-Object System.Drawing.Bitmap 512, 512
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

    $bg = [System.Drawing.Color]::FromArgb(255, 12, 42, 24)
    $panel = [System.Drawing.Color]::FromArgb(255, 37, 120, 55)
    $accent = [System.Drawing.Color]::FromArgb(255, 155, 220, 130)
    $dark = [System.Drawing.Color]::FromArgb(255, 8, 22, 12)
    $white = [System.Drawing.Color]::FromArgb(255, 235, 250, 225)

    $graphics.Clear($bg)

    $brushPanel = New-Object System.Drawing.SolidBrush $panel
    $brushAccent = New-Object System.Drawing.SolidBrush $accent
    $brushDark = New-Object System.Drawing.SolidBrush $dark
    $brushWhite = New-Object System.Drawing.SolidBrush $white
    $penAccent = New-Object System.Drawing.Pen $accent, 10
    $penWhite = New-Object System.Drawing.Pen $white, 5

    $graphics.FillRectangle($brushPanel, 52, 102, 408, 290)
    $graphics.DrawRectangle($penAccent, 52, 102, 408, 290)

    $points = @(
        [System.Drawing.Point]::new(52, 102),
        [System.Drawing.Point]::new(256, 36),
        [System.Drawing.Point]::new(460, 102)
    )
    $graphics.DrawLines($penAccent, $points)
    $graphics.DrawLine($penWhite, 256, 36, 256, 392)
    $graphics.DrawLine($penWhite, 154, 102, 154, 392)
    $graphics.DrawLine($penWhite, 358, 102, 358, 392)
    $graphics.DrawLine($penWhite, 52, 242, 460, 242)

    $graphics.FillRectangle($brushDark, 115, 330, 282, 44)
    $graphics.FillEllipse($brushAccent, 150, 285, 34, 34)
    $graphics.FillEllipse($brushAccent, 215, 276, 34, 34)
    $graphics.FillEllipse($brushAccent, 280, 285, 34, 34)
    $graphics.FillEllipse($brushAccent, 345, 276, 34, 34)

    $fontTitle = New-Object System.Drawing.Font "Arial", 34, ([System.Drawing.FontStyle]::Bold)
    $fontSmall = New-Object System.Drawing.Font "Arial", 24, ([System.Drawing.FontStyle]::Bold)
    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $graphics.DrawString("GHI", $fontTitle, $brushWhite, [System.Drawing.RectangleF]::new(0, 405, 512, 45), $format)
    $graphics.DrawString("HEMP GREENHOUSE", $fontSmall, $brushWhite, [System.Drawing.RectangleF]::new(0, 452, 512, 45), $format)

    $bitmap.Save($ImagePath, [System.Drawing.Imaging.ImageFormat]::Png)

    $graphics.Dispose()
    $bitmap.Dispose()
    $brushPanel.Dispose()
    $brushAccent.Dispose()
    $brushDark.Dispose()
    $brushWhite.Dispose()
    $penAccent.Dispose()
    $penWhite.Dispose()
    $fontTitle.Dispose()
    $fontSmall.Dispose()
    $format.Dispose()
}

function Ensure-ModIcon {
    param([string]$ModFolder)

    $iconPath = Join-Path $ModFolder "icon_mod.dds"
    if (-not (Test-Path $iconPath)) {
        New-PlaceholderDdsIcon -IconPath $iconPath
        Write-Host "Generated alpha placeholder icon: $iconPath" -ForegroundColor Yellow
    }
    else {
        Write-Host "Icon exists: $iconPath" -ForegroundColor Green
    }
}

function Ensure-StoreImage {
    param([string]$ModFolder)

    $imagePath = Join-Path $ModFolder "store\store_hempGreenhouse.png"
    if (-not (Test-Path $imagePath)) {
        New-PlaceholderStorePng -ImagePath $imagePath
        Write-Host "Generated alpha placeholder store image: $imagePath" -ForegroundColor Yellow
    }
    else {
        Write-Host "Store image exists: $imagePath" -ForegroundColor Green
    }
}

function Test-ZipRoot {
    param([string]$ZipPath)

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
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

function Remove-OldModInstall {
    param(
        [string]$ModsDir,
        [string]$Name
    )

    $target = Join-Path $ModsDir $Name
    if (Test-Path $target) {
        $item = Get-Item $target
        if ($item.PSIsContainer) {
            Remove-Item $target -Recurse -Force
            Write-Host "Removed old loose mod folder: $target" -ForegroundColor Yellow
        }
        else {
            Remove-Item $target -Force
            Write-Host "Removed old mod file: $target" -ForegroundColor Yellow
        }
    }
}

$repoRoot = Find-RepoRoot
$modFolder = Join-Path $repoRoot "FS25_GreenHorizonIndustries"
$modDescPath = Join-Path $modFolder "modDesc.xml"
$distDir = Join-Path $repoRoot "dist"
$zipPath = Join-Path $distDir "FS25_GreenHorizonIndustries.zip"
$version = Get-ModVersion -ModDescPath $modDescPath

Write-Host "Green Horizon Industries Windows Packager" -ForegroundColor Green
Write-Host "Repo: $repoRoot"
Write-Host "Mod folder: $modFolder"
Write-Host "Version: $version"

if (-not (Test-Path $modFolder)) {
    throw "Missing mod folder: $modFolder"
}

if (-not (Test-Path $modDescPath)) {
    throw "Missing modDesc.xml: $modDescPath"
}

Ensure-ModIcon -ModFolder $modFolder
Ensure-StoreImage -ModFolder $modFolder

New-Item -ItemType Directory -Force -Path $distDir | Out-Null

if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

$items = Get-ChildItem -Path $modFolder -Force
Compress-Archive -Path $items.FullName -DestinationPath $zipPath -CompressionLevel Optimal

if (-not (Test-ZipRoot -ZipPath $zipPath)) {
    throw "Bad zip root. modDesc.xml is not at the top of the zip. Do not use this zip."
}

Write-Host "Created: $zipPath" -ForegroundColor Cyan
Write-Host "Zip root check: PASS - modDesc.xml is at the top of the zip." -ForegroundColor Green

if ($CleanOldZips) {
    New-Item -ItemType Directory -Force -Path $ModsDir | Out-Null
    $oldNames = @(
        "FS25_GreenHorizonIndustries.zip",
        "FS25_GreenHorizonIndustries",
        "FS25_Hemp_Industries.zip",
        "FS25_Hemp_Industries"
    )

    foreach ($name in $oldNames) {
        Remove-OldModInstall -ModsDir $ModsDir -Name $name
    }
}

if ($Install) {
    New-Item -ItemType Directory -Force -Path $ModsDir | Out-Null
    Copy-Item -Path $zipPath -Destination (Join-Path $ModsDir "FS25_GreenHorizonIndustries.zip") -Force
    Write-Host "Installed zip to: $ModsDir" -ForegroundColor Cyan
}

if ($InstallLoose) {
    New-Item -ItemType Directory -Force -Path $ModsDir | Out-Null
    $looseTarget = Join-Path $ModsDir "FS25_GreenHorizonIndustries"
    if (Test-Path $looseTarget) {
        Remove-Item $looseTarget -Recurse -Force
    }
    Copy-Item -Path $modFolder -Destination $ModsDir -Recurse -Force
    Write-Host "Installed loose folder to: $looseTarget" -ForegroundColor Cyan
    Write-Host "Use the loose folder for GIANTS Icon Generator testing." -ForegroundColor Cyan
}

Write-Host "Done. In FS25, confirm the mod list shows version $version." -ForegroundColor Green
