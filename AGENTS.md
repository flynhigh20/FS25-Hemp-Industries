# Repository Agent Instructions

## Scope

These instructions apply to automated coding agents, Codex sessions, and GitHub-connected assistants working in `flynhigh20/FS25-Hemp-Industries`.

## Repository safety

- Use a feature branch and pull request. Do not force-push `main`.
- Do not upload extracted GIANTS base-game files or copyrighted game assets.
- Do not modify the separate private bee-smoker mod repository unless the user explicitly requests it.
- Fetch the current file before editing it. The user frequently uploads newer XML/I3D/Lua versions locally.
- Preserve confirmed working behavior. Do not replace proven systems merely to silence warnings.

## GIANTS mapping rules

- XML mappings are relative to the loaded I3D root.
- Root mapping: `0>`.
- Direct children: `0>0`, `0>1`, and so on.
- Do not include the GIANTS Editor scene-root index in exported runtime mappings.
- Recalculate paths after hierarchy changes.
- A TransformGroup and a Shape are not interchangeable. Inspect node type before generating an effect preset.

## Effects and particles

Read `tools/giants/apiaryDevelopmentToolkit/docs/effectResearchNotes.md` before changing effect tooling.

Confirmed behavior:

- `g_effectManager` works on hand tools when the effect class and selected node type are compatible.
- A stock pressure-washer effect pair renders and starts/stops correctly.
- `PipeEffect` animates stream geometry; it is not drifting smoke.
- An imported Shape with `materialType="unloadingSmoke"` renders, but its authored plume geometry may be unsuitable.
- `particleType="smoke"` and `particleType="SMOKE"` are unverified and have loaded without visible output.
- `loaded=true` means an effect entry instantiated; it does not prove visible rendering.

Do not:

- claim a generic Shape is ready for smoke merely because it has geometry;
- label generic smoke-particle presets as confirmed working;
- pass a TransformGroup to `ShaderPlaneEffect` or another Shape/material-based effect class;
- generate an `<effectNode>` for an attachment TransformGroup;
- assume an external asset path in `log.txt` was loaded by the object under test.

## Dynamic parts compatibility

- `<dynamicallyLoadedParts>` is supported through vehicle/placeable specialization contexts.
- Hand tools do not automatically process that XML section.
- Before generating dynamic-part XML, detect the target object type.
- For a hand tool, use custom Lua loading or direct I3D import instead.
- Generated hand-tool instructions must include all of the following when applicable:
  - XML schema registration;
  - XML attribute on the specialization element;
  - I3D mapping;
  - Lua load and attachment code;
  - visibility/start-stop control;
  - cleanup in `onDelete`;
  - source-file registration when a new Lua file is introduced.

## Bee-smoker chimney-smoke test contract

The external smoke attachment is a TransformGroup named `chimneySmokeLink`.

Expected XML pattern:

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

During this test:

- remove the XML `<effects>` block;
- remove any hand-tool `<dynamicallyLoadedParts>` block;
- do not map `chimneySmokeLink` as an `<effectNode>`;
- load `$data/effects/chimneySmoke/smokeTrailSubUV.i3d` through the custom hand-tool Lua;
- attach the loaded root beneath `chimneySmokeLink`;
- hide it by default and toggle it during the smoker action;
- delete the loaded root during cleanup;
- add uniquely prefixed logging for load, attachment, child count, and failure reason.

## Toolkit requirements

The toolkit should:

- classify the target XML/object type before printing implementation guidance;
- distinguish Shape, TransformGroup, and unsupported nodes;
- warn when a selected node cannot satisfy the chosen effect class;
- distinguish material particles (`WASHER_WATER`, `STONE`) from shader smoke meshes (`unloadingSmoke`);
- describe particle readiness as structural compatibility unless visible output is proven;
- avoid hidden prerequisites in generated instructions;
- preserve known-correct root and mapping export behavior.

## Validation discipline

- Test one effect system at a time.
- Keep original asset scale/material setup until the effect is visibly confirmed.
- Add tuning only after rendering is proven.
- Use explicit log lines rather than inferring success from absence of errors.
- When a test fails, record the exact XML/Lua configuration and result in the research notes.
