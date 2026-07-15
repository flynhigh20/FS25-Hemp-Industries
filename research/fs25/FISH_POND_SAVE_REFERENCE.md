# FS25 Fish Pond Save Reference

Observed in `savegame1/placeables.xml` on 2026-07-14.

The Highlands Fishing Expansion lake-style fish pond is persisted as a normal
placeable with a production-point storage child:

```xml
<placeable
    modName="pdlc_highlandsFishingPack"
    filename="$pdlcdir$highlandsFishingPack/placeables/brandless/fishFarmLake/fishFarmLake.xml"
    uniqueId="placeable28db791c00266facaa5d4a61e945576f"
    position="-697.097 47.000 159.996"
    rotation="0.00 -0.00 0.00"
    age="0.000000"
    price="12000.000000"
    farmId="1">
    <productionPoint>
        <storage farmId="1" />
    </productionPoint>
</placeable>
```

## Useful implementation details

- The save points back to the source XML through `filename`; it does not embed
  the pond model or production recipe in the savegame.
- Placement state is stored through `position`, `rotation`, `farmId`, `price`,
  `age`, and `uniqueId`.
- Production inventory belongs under `productionPoint/storage`. The observed
  pond had no stored fill-level entries, so its storage element was empty.
- Fish food is registered in the same save as fill type `FISHFOOD`.
- The source asset lives inside the packed DLC file
  `pdlc/highlandsFishingPack.dlc`, so its full placeable XML is not exposed as a
  normal loose game-data file.

For a future Green Horizon pond, use a normal project-owned placeable XML with
`productionPoint` storage and allow FS25 to generate the save entry. Do not
hard-code a `uniqueId` or a savegame position in the mod files.
