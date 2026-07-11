param(
    [string]$RepoRoot = "",
    [string]$TextureTool = "C:\Program Files\GIANTS Software\GIANTS_Editor_10.0.13\tools\textureTool.exe"
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

$i3d = Join-Path $RepoRoot "FS25_GreenHorizonIndustries\placeables\greenhouses\i3d\greenHorizonHempGreenhouse.i3d"
$textureDir = Join-Path $RepoRoot "FS25_GreenHorizonIndustries\placeables\greenhouses\textures"

if (-not (Test-Path -LiteralPath $i3d)) {
    throw "Missing greenhouse I3D: $i3d"
}
if (-not (Test-Path -LiteralPath $TextureTool)) {
    throw "Missing GIANTS texture tool: $TextureTool"
}

[xml]$document = Get-Content -LiteralPath $i3d -Raw

# Blender's basic materials export with a full-white emissive value, which
# overwhelms their image textures in FS25. Use ordinary diffuse materials and
# retain alpha blending only for the greenhouse glazing.
foreach ($material in $document.i3D.Materials.Material) {
    $material.RemoveAttribute("emissiveColor")
    $material.RemoveAttribute("specularColor")
    if ($material.name -eq "clearPolycarbonate") {
        $material.SetAttribute("alphaBlending", "true")
    }
}

# Convert every active greenhouse image to a mipmapped DDS with GIANTS' own
# texture tool, then point the I3D at the DDS. PNG sources remain in the repo.
foreach ($fileNode in $document.i3D.Files.File) {
    $filename = [string]$fileNode.filename
    if ($filename -notmatch '^\.\./textures/(.+)\.png$') {
        continue
    }

    $sourceName = [System.IO.Path]::GetFileName($filename)
    $sourcePath = Join-Path $textureDir $sourceName
    $ddsPath = [System.IO.Path]::ChangeExtension($sourcePath, ".dds")
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Missing source texture: $sourcePath"
    }

    # textureTool writes normal conversion progress to stderr, which PowerShell
    # can incorrectly promote to a terminating NativeCommandError. Reuse a fresh
    # DDS when available; otherwise run it as a waited isolated process.
    $sourceItem = Get-Item -LiteralPath $sourcePath
    $ddsItem = Get-Item -LiteralPath $ddsPath -ErrorAction SilentlyContinue
    if ($null -eq $ddsItem -or $ddsItem.LastWriteTimeUtc -lt $sourceItem.LastWriteTimeUtc) {
        $conversion = Start-Process -FilePath $TextureTool -ArgumentList @($sourcePath) -Wait -PassThru -WindowStyle Hidden
    }
    if (-not (Test-Path -LiteralPath $ddsPath)) {
        $exitCode = if ($null -ne $conversion) { $conversion.ExitCode } else { "not started" }
        throw "Texture conversion did not create $ddsPath (exit code $exitCode)"
    }

    $fileNode.SetAttribute("filename", ("../textures/" + [System.IO.Path]::GetFileName($ddsPath)))
}

function Set-ShapeAttributes {
    param(
        [System.Xml.XmlElement]$Node,
        [hashtable]$Attributes
    )
    foreach ($entry in $Attributes.GetEnumerator()) {
        $Node.SetAttribute([string]$entry.Key, [string]$entry.Value)
    }
}

# FS25 building collision convention, copied from the stock large greenhouse.
foreach ($node in $document.SelectNodes("//Shape[starts-with(@name, 'collision')]") ) {
    Set-ShapeAttributes $node @{
        static = "true"
        collisionFilterGroup = "0x1034"
        collisionFilterMask = "0xfffffbff"
        nonRenderable = "true"
        castsShadows = "false"
        receiveShadows = "false"
    }
}

foreach ($name in @("playerTrigger", "infoTrigger", "door1Trigger")) {
    $node = $document.SelectSingleNode("//Shape[@name='$name']")
    if ($null -eq $node) { throw "Missing trigger shape: $name" }
    Set-ShapeAttributes $node @{
        static = "true"
        trigger = "true"
        collisionFilterGroup = "0x20000000"
        collisionFilterMask = "0x100000"
        nonRenderable = "true"
        castsShadows = "false"
        receiveShadows = "false"
    }
}

$doorCollision = $document.SelectSingleNode("//Shape[@name='collisionFrontDoor']")
if ($null -eq $doorCollision) { throw "Missing animated door collision" }
$doorCollision.RemoveAttribute("static")
Set-ShapeAttributes $doorCollision @{
    kinematic = "true"
    collisionFilterGroup = "0x3e"
    collisionFilterMask = "0xfffffbff"
    density = "0.0001"
    nonRenderable = "true"
    castsShadows = "false"
    receiveShadows = "false"
}

$exactFill = $document.SelectSingleNode("//Shape[@name='exactFillRootNode']")
if ($null -eq $exactFill) { throw "Missing exactFillRootNode shape" }
Set-ShapeAttributes $exactFill @{
    kinematic = "true"
    compound = "true"
    collisionFilterGroup = "0x40000000"
    collisionFilterMask = "0x20000000"
    nonRenderable = "true"
    castsShadows = "false"
    receiveShadows = "false"
}

$palletTrigger = $document.SelectSingleNode("//Shape[@name='palletTrigger']")
if ($null -eq $palletTrigger) { throw "Missing palletTrigger shape" }
Set-ShapeAttributes $palletTrigger @{
    kinematic = "true"
    compound = "true"
    trigger = "true"
    collisionFilterGroup = "0x20000000"
    collisionFilterMask = "0x10000"
    nonRenderable = "true"
    castsShadows = "false"
    receiveShadows = "false"
}

$settings = New-Object System.Xml.XmlWriterSettings
$settings.Indent = $true
$settings.Encoding = New-Object System.Text.UTF8Encoding($false)
$writer = [System.Xml.XmlWriter]::Create($i3d, $settings)
try {
    $document.Save($writer)
}
finally {
    $writer.Dispose()
}

Write-Host "Finalized FS25 greenhouse I3D materials, DDS textures, triggers, and collisions." -ForegroundColor Green
