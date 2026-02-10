# Layer 01 — 15-Minute Mobile Onboarding Loop

This layer operationalizes BURZEN's mobile-first thesis into a playable first session.

## Why this layer first

It is the narrowest slice that validates all core claims simultaneously:

- Touch-native cognition (gesture semantics over UI)
- Stateful tower mechanics (thermal constraints)
- Field-based pathing (cost gradients over lanes)
- Fast failure-learning loop (model collapse in minutes)

## Session objective

Within 15 minutes, a new player should be able to:

1. Place and rotate at least one thermal tower.
2. Observe overheat from misuse.
3. Recover by modifying placement and fire cadence.
4. Complete one wave by reasoning, not memorization.

## Time-boxed loop

### 0:00–2:00 — Silent affordance introduction

- No text tutorial overlays.
- Show a ghost tower and a pulsing heat ring.
- Prompt with icon-only gestures:
  - Drag: place vector anchor
  - Rotate: adjust orientation basis
  - Long-press: inspect rule card

### 2:00–6:00 — First contradiction

- Single enemy stream enters a low-cost basin.
- Player can only place one tower.
- Rapid firing causes deterministic overheat.
- Failure state is visual/haptic:
  - Heat bloom shader
  - Brief vibration pulse
  - Tower lockout ring

### 6:00–10:00 — Constraint discovery

- Introduce cooldown-by-entropy meter (iconic, no text).
- Player discovers spacing + cadence solution.
- Terrain edit micro-action unlocks (raise local cost tile).

### 10:00–15:00 — Proof of understanding

- Wave with two path options and one thermal trap.
- Success condition: survive with <1 overheat event.
- End-of-loop recap is a replay strip, not prose:
  - Overheat moments
  - Path divergence
  - Corrected placements

## Prototype acceptance criteria

A prototype is accepted when all are true:

- Median new-user completion time <= 15 minutes.
- At least one intentional overheat-recovery cycle occurs.
- >= 80% of players use long-press inspection at least once.
- Session runs one-handed on phone portrait mode.

## Instrumentation events

- `gesture_drag_tower`
- `gesture_rotate_tower`
- `tower_overheat`
- `tower_recovered`
- `path_cost_tile_modified`
- `wave_01_completed`

## Minimal implementation map

- `simulation/thermal_models.py`: thermal truth model
- `engine/<unity|godot>/`: touch input + state presentation
- `tests/`: deterministic replay for overheat sequence

## Handoff to Layer 02

After this slice is stable, descend into **Layer 02 — Codex contributor prompt templates** to standardize mechanic-to-code translation across collaborators.
