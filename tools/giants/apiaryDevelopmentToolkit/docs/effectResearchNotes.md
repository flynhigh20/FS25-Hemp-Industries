# GIANTS Effect Research Notes

## Core conclusions

- Hand tools can load and start effects through `g_effectManager`.
- `PipeEffect` drives visible stream geometry toward a `controlPoint`. A normal mesh may visibly extend and retract like a tube.
- `positionUpdateNodes` repositions companion nodes; it does not create smoke by itself.
- `ParticleEffect` is the preferred controllable effect class for a bee-smoker puff.
- A transform-only node is suitable for linking an externally loaded smoke asset, but it is not automatically a ParticleEffect emitter.
- Dynamic chimney smoke uses a complete external asset and may require custom Lua visibility control on a hand tool.
- XML mappings must be relative to the loaded I3D root. `rootNode` is `0>`, direct children are `0>0`, `0>1`, and so on.

## Conservative ParticleEffect test

```xml
<effects>
    <effectNode
        effectNode="smokeEmitter"
        effectClass="ParticleEffect"
        particleType="smoke"
        emitCountScale="1"
        alphaScale="1"
        delay="0"
        worldSpace="true"/>
</effects>
```

Start without `materialType`. Names such as `smokeParticle` can depend on additional material registrations or stock-authored assets. Add material overrides only after the minimal particle test renders.

## Diagnostic interpretation

- `count=1 loaded=true` confirms the XML effect entry loaded. It does not prove the selected emitter geometry or particle registration can render.
- A working washer spray proves the action handling, effect-manager loading, start/stop calls, and mapping path are functioning.
- A PipeEffect tube extending and retracting proves the PipeEffect class is functioning, but it is not evidence of particle smoke.
- No visible ParticleEffect with no load error points toward emitter suitability, particle registration, material resolution, or authored particle data.

## Toolkit features derived from the research

- Schema-aware effect inspection.
- PipeEffect visible-geometry warning.
- ParticleEffect readiness check.
- Conservative smoke XML preset with no material override.
- Effect-ID and mapping validation.
- I3D-relative path correction and root mapping export.
- Dynamic smoke-link preset for externally loaded smoke assets.

## Recommended testing order

1. Validate `rootNode="0>"` and all effect mappings.
2. Select the intended emitter in the Particle Check tab.
3. Confirm that Shape geometry exists or compare the node against a proven stock emitter shape.
4. Print and test the conservative ParticleEffect preset.
5. Begin with `emitCountScale="1"`.
6. Tune scale, alpha, world-space behavior, rotation, and position only after smoke is visible.
7. Use dynamic chimney smoke with custom Lua control only if ParticleEffect cannot deliver the desired visual.
