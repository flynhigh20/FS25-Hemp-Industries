# FS25 Research Links

## Priority References

### Greenhouse
- PlaceableGreenhouse
- greenhousePlant XML schema

Use for:
- Hemp greenhouse
- Plant stage models
- Withered plant model
- Output fill-type changes

### Core Registration
- FillTypeDesc
- FillTypeManager
- FruitTypeDesc
- FruitTypeManager

Use for:
- Registering GHI_HEMP and related materials
- Connecting the field crop to its harvested fill type
- Avoiding name conflicts with other hemp mods

### Production
- PlaceableProductionPoint
- ProductionPoint
- PlaceableSellingStation

Use for:
- Fiber Mill
- Oil Press
- Rope Factory
- Hempcrete Plant
- Eco Materials Depot

### Later: PC Enhancement / Equipment
- SpecializationManager
- Combine
- Cutter
- AIFieldWorker
- WorkArea
- WindBending
- PrecisionFarmingStatistic

## FS25 Mapping Tutorial - Selling Stations
https://gdn.giants-software.com/videoTutorials2.php?s=1&p=0&c=7&LANGUAGE=en

Use for:
- Hemp sell point
- Eco Materials Depot
- Fiber buyer
- Grain/storage triggers
- Placeable organization

FillTypeDesc:
https://gdn.giants-software.com/documentation_scripting_fs25.php?version=script&category=36&class=408

## FS25 LuaDoc - Fill Types
Important:
FS25 fill types use child nodes for image, physics, and economy.
Use this before finalizing mod/xml/fillTypes.xml.

LUADOC - FARMING SIMULATOR 22
##https://gdn.giants-software.com/documentation_scripting_fs22.php

## GIANTS Developer Network Downloads
https://gdn.giants-software.com/downloads.php

Useful tools:
- GIANTS Editor v10.0.13
- Farming Simulator 25 Icon Generator v10.0.4
- Farming Simulator 25 Test Runner v0.9.18
- Blender Exporter Plugins v10.0.2

## XML Validation / Schema Reference
https://validation.gdn.giants-software.com/fs22/overview.html

Notes:
- FS22 schema reference only.
- Useful for structure comparison.
- Must verify against FS25 files before final use.
