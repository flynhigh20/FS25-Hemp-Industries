param(
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
)

$i3dFolder = Join-Path $RepoRoot "FS25_GreenHorizonIndustries\pallets\i3d"
$sourcePath = Join-Path $i3dFolder "greenhorizonproductpallets.i3d"

if (-not (Test-Path -LiteralPath $sourcePath)) {
    throw "Missing combined pallet export: $sourcePath"
}

$targets = @(
    @{ Root = "pallet_hemp"; File = "hempPallet.i3d" },
    @{ Root = "pallet_flower"; File = "flowerPallet.i3d" },
    @{ Root = "pallet_biomass"; File = "biomassPallet.i3d" }
)

foreach ($target in $targets) {
    $document = [System.Xml.XmlDocument]::new()
    $document.PreserveWhitespace = $true
    $document.Load($sourcePath)

    $scene = $document.SelectSingleNode("/i3D/Scene")
    $root = $scene.SelectSingleNode("*[@name='$($target.Root)']")
    if ($null -eq $root) {
        throw "Missing pallet root '$($target.Root)' in $sourcePath"
    }

    foreach ($child in @($scene.ChildNodes)) {
        if (-not [object]::ReferenceEquals($child, $root)) {
            [void]$scene.RemoveChild($child)
        }
    }

    # The combined Blender layout spaces each pallet apart for editing. A
    # vehicle I3D must have its component root at the file origin.
    [void]$root.RemoveAttribute("translation")

    $destination = Join-Path $i3dFolder $target.File
    $settings = [System.Xml.XmlWriterSettings]::new()
    $settings.Encoding = [System.Text.UTF8Encoding]::new($false)
    $settings.Indent = $false
    $writer = [System.Xml.XmlWriter]::Create($destination, $settings)
    try {
        $document.Save($writer)
    }
    finally {
        $writer.Dispose()
    }

    Write-Host "Created $($target.File) from $($target.Root)"
}
