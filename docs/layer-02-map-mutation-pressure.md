# Layer 02 — Map Mutation Pressure Runtime

This layer operationalizes the **Map Mutation Layer (Editable)** from the mutable-universe model.

## Why this layer next

It is the thinnest implementation slice that turns BURZEN maps from static layouts into local rule contracts:

- Tower thermal profiles now depend on map mutation coefficients.
- Enemy velocity is no longer fixed and reacts to player efficiency + global heat pressure.
- Per-map metadata (name, fog-density proxy) surfaces in HUD to make rule context legible.

## Runtime contract

Each generated level now carries a deterministic mutation profile:

```text
MapMutation {
  map_name
  heat_global_multiplier
  enemy_scaling_exponent
  fog_density
  heat_feedback_gain
  heat_decay_coefficient
}
```

## First operational behaviors

1. **Escalation Pressure Field**
   - High score efficiency increases enemy speed via exponent-based scaling.
   - Captures the "power attracts counter-power" loop.

2. **Heat Feedback Arena**
   - Tower fleet heat is aggregated into a global pressure signal.
   - Global pressure contributes to enemy speed acceleration.

3. **Rule Identity per map seed**
   - Level generator selects a mutation preset (Angel/DotA/Twilight/Mafia inspired labels).
   - Preset values scale slightly by level index for deterministic progression.

## Acceptance checks

- Mutation profile appears in level header when run starts.
- Tower heat behavior changes between seeds due to heat multiplier.
- Enemy movement speed changes during a run as score efficiency and pressure evolve.

## Next layer options

After this slice, two credible continuations are unlocked:

- **Layer 03A:** Hidden-rule multiplayer protocol (role-scoped mutation authority).
- **Layer 03B:** External map format (`.json`) loader + validation for shareable forks.
