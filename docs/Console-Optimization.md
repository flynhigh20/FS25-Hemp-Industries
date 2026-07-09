# Console Optimization Checklist

This project has a console goal, so every future asset and XML feature should be designed with size, memory, and slot impact in mind.

## Main Console Strategy

Build the mod like this from the beginning:

```text
small number of placeables
shared texture sets
clean low-poly models
simple XML
no custom scripts unless absolutely necessary
no copied base-game assets in the repo
```

## File Size Rules

Prefer:

```text
DDS textures
small texture atlases
shared textures across multiple assets
one texture family for Green Horizon buildings
one texture family for pallets/products
reasonable resolution, not oversized
```

Avoid:

```text
unique texture files for every tiny object
uncompressed images
huge 4K textures unless truly needed
unused exported texture files
duplicate texture folders
```

## Geometry / Slot Rules

Every placeable should be built like it has a slot budget.

Prefer:

```text
simple wall/roof meshes
merged static detail where reasonable
low-poly props
few material slots
few separate objects/nodes
simple collision shapes
```

Avoid:

```text
high-poly decorative clutter
many tiny loose mesh objects
complex collision mesh
unnecessary bevel-heavy geometry
hidden objects left inside exported i3d files
multiple unique variants when one reusable model can work
```

## Placeable Count Strategy

Keep the mod progression compact.

Recommended placeables:

```text
1. Hemp Greenhouse
2. Hemp Buyer / Simple Selling Point
3. CBD Plant Small
4. CBD Plant Large or Distribution Center
```

Avoid adding too many single-purpose buildings early.

## Upgrade Design Strategy

For console-friendliness, prefer tiered placeables over a custom scripted upgrade system.

Good:

```text
Small CBD Plant
Large CBD Plant
Distribution Center
```

Riskier:

```text
custom script upgrade button
custom upgrade UI
complex runtime model swapping
```

## XML Rules

Prefer:

```text
clear fill type names
short store item list
simple production recipes
simple selling station setup
shared production XML patterns
```

Avoid:

```text
duplicate copied XML blocks without cleanup
unused store items
unused productions
experimental categories left active
old test paths left in released XML
```

## Texture Naming Plan

Use predictable names later:

```text
ghi_buildings_diffuse.dds
ghi_buildings_normal.dds
ghi_buildings_specular.dds
ghi_products_diffuse.dds
ghi_products_normal.dds
ghi_products_specular.dds
```

Try to reuse these across:

```text
greenhouse
CBD plant
selling point
pallets
small props
```

## Blender Export Cleanup

Before exporting to i3d:

```text
apply scale
remove hidden test geometry
remove unused materials
remove unused images
check normals
use simple collision placeholders
keep object names readable
keep helper markers separate from final visible mesh
```

## GIANTS Editor Cleanup

Before packaging:

```text
check missing resources
check material count
check texture paths
check collision
check clip distances
check node count
remove unused helper-only objects if they should not export
```

## Store Image / Icon Strategy

Use clean compressed DDS files.

Do not create multiple large store renders for every tiny variant.

Recommended:

```text
one mod icon
one greenhouse store image
one CBD plant store image
one selling point store image
```

## Release Rule

Before a console-target release candidate, run a full audit:

```text
package size
texture count
unique material count
placeable count
node/object count
log warnings
missing resources
unused files
```

Do not add visual detail unless it improves gameplay or player recognition.
