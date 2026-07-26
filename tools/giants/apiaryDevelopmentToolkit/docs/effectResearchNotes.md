# GIANTS Effect Research Notes

## Confirmed conclusions

- Hand tools can load and start XML effects through `g_effectManager` when the selected effect class and node type are compatible.
- `PipeEffect` drives visible stream geometry toward a `controlPoint`. It can make a mesh extend and retract like a tube, but it is not drifting smoke.
- `positionUpdateNodes` repositions companion nodes; it does not create smoke.
- A stock pressure-washer pair is confirmed working on the smoker:
  - shader mesh effect using `materialType="WASHER"`
  - `ParticleEffect` using `particleType="WASHER_WATER"`
- `ParticleEffect` entries using `particleType="smoke"` or `particleType="SMOKE"` can report `loaded=true` and still render nothing. These smoke particle names are not verified as usable registrations for this hand tool.
- A generic Shape is not automatically a functional smoke emitter. A proven stock emitter Shape can still fail if the requested particle type is not registered or is incompatible.
- The dredging-boat example separates material particles from smoke/dust:
  - `ParticleEffect` handles a material type such as `STONE`.
  - a separate shader mesh with `materialType="unloadingSmoke"` handles the smoke/dust visual.
- An imported `effectSmoke` shader mesh using `materialType="unloadingSmoke"` is confirmed to render on the hand tool.
- The imported unloading-smoke mesh has a tall, twisted plume silhouette. Scaling it down makes it faint; scaling it up exposes the unsuitable "mini tornado" geometry. Material changes do not change that geometry.
- A transform-only node is valid as an attachment/link node, but it must not be passed to `ShaderPlaneEffect` or another effect class that expects a Shape with materials.
- XML mappings must be relative to the loaded I3D root. `rootNode` is `0>`, direct children are `0>0`, `0>1`, and so on.

## Dynamic loading boundary

- `<dynamicallyLoadedParts>` is a specialization feature used by vehicles and placeables.
- A hand-tool XML does not automatically process `<dynamicallyLoadedParts>`.
- For a hand tool, an external I3D effect such as chimney smoke must be loaded and attached through custom Lua, or imported directly into the hand-tool I3D.
- A vehicle exhaust node is commonly only an attachment point. The actual exhaust effect can be loaded from an external asset, for example `$data/effects/exhaust/exhaust.i3d`.
- Do not assume that the absence of an XML error means an unsupported XML section executed.

## Confirmed working shader-mesh pattern

```xml
<effects>
    <effectNode
        effectNode="effectSmoke"
        materialType="unloadingSmoke"
        fadeTime="0.50"/>
</effects>
```

Requirements:

1. `effectSmoke` must map to the actual Shape, not a parent TransformGroup.
2. Preserve the imported Shape's original material and shader setup.
3. Keep the Shape scale at `1 1 1` when possible.
4. Use a parent TransformGroup for uniform size, position, and rotation adjustment.
5. Judge the authored mesh silhouette at visible scale before investing in tuning.

## External chimney-smoke hand-tool pattern

Use a TransformGroup such as `chimneySmokeLink` at the nozzle and map it in XML:

```xml
<beeSmoker
    bellowsNode="bellowsPivot"
    chimneySmokeLink="chimneySmokeLink">
    <sounds>
        <!-- puff sample -->
    </sounds>
</beeSmoker>

<i3dMapping id="chimneySmokeLink" node="0>1|19" />
```

The custom specialization must:

1. register `handTool.beeSmoker#chimneySmokeLink` as a `NODE_INDEX`;
2. resolve the mapped node during `onLoad`;
3. load `$data/effects/chimneySmoke/smokeTrailSubUV.i3d` through Lua;
4. link the loaded root under `chimneySmokeLink`;
5. hide it by default and toggle visibility during the smoker action;
6. delete the loaded root during `onDelete`.

Do not also pass `chimneySmokeLink` through `g_effectManager`. It is a TransformGroup attachment node, not a shader-plane Shape.

## Failed or misleading tests

- `particleType="smoke"` and `particleType="SMOKE"`: loaded but produced no visible smoke.
- Adding `materialType="smokeParticle"`: did not produce visible smoke.
- `PipeEffect`: visible stream geometry worked, but the result was a retracting/extending tube, not smoke.
- Imported unloading-smoke Shape at very small scale: technically rendered but was too faint.
- Imported unloading-smoke Shape at larger scale: exposed unsuitable tall/twisted geometry.
- `<dynamicallyLoadedParts>` inside the hand-tool XML: ignored because the hand-tool type does not own that specialization.
- Mapping a TransformGroup as an `<effectNode>` with `materialType="unloadingSmoke"`: caused `ShaderPlaneEffect` to call material functions on a non-Shape node and break loading.

## Diagnostic interpretation

- `count=1 loaded=true` confirms the XML effect entry was instantiated. It does not prove the particle registration, emitter data, material, or geometry can render.
- A working washer spray proves action handling, effect-manager loading, start/stop calls, and mapping are functioning.
- A working PipeEffect proves only that PipeEffect is functioning.
- An external I3D path appearing in the log does not prove the hand tool loaded it; the map or another object may already use that asset.
- Add explicit, uniquely prefixed log messages for custom Lua loading and attachment.
- If `getNumOfMaterials` reports an invalid entity type, a TransformGroup or other non-Shape node was passed to a Shape-based effect class.

## Toolkit corrections required

The toolkit must not present generic smoke particles as confirmed working.

- Label `particleType="smoke"` as unverified and known to load without visible output in this test context.
- Distinguish registered material particles such as `WASHER_WATER` and `STONE` from shader smoke meshes such as `unloadingSmoke`.
- Particle Check must report structural compatibility only; it must not claim a Shape is "ready for smoke" without a proven particle registration.
- Effects inspection must identify whether the selected node is a Shape or TransformGroup before printing an effect preset.
- Never generate a Shape-based `<effectNode>` for a TransformGroup.
- Dynamic-part helpers must first classify the XML/object type:
  - vehicle/placeable: specialization-based dynamic parts may be valid;
  - hand tool/other type: generate or recommend custom Lua loading instead.
- Generated instructions must include every required XML attribute, mapping, source-file registration, and Lua dependency. Do not leave hidden linking steps.

## Recommended testing order

1. Identify the object type and available specializations before generating XML.
2. Validate `rootNode="0>"` and all effect mappings.
3. Classify the selected node as Shape or TransformGroup.
4. Test one effect system at a time.
5. Use a proven stock particle type before experimenting with unverified names.
6. For shader meshes, test at original scale first to inspect the authored silhouette.
7. For external hand-tool assets, load through custom Lua and add explicit load/attach logs.
8. Tune scale, alpha, rotation, and timing only after visible rendering is confirmed.
