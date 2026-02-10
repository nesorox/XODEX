# Vision

## Version
- Document version: **CODEX v0.002**
- Project target: **BURZEN Tower Defense prototype v0.00.1**

## Purpose & justification
This document defines the operating intent for the prototype. The current phase focuses on a geometry-only, touch-first Android simulation loop to prove the thermal pressure mechanic before adding content or UX layers.

## Input / output behavior
- **Inputs:** tap, long-press, two-finger tap, simulation ticks.
- **Outputs:** deterministic tower/enemy interactions, thermal lockout/recovery states, fast failure-reset loop.

## Examples
- A player repeatedly taps to place towers, then long-presses to inspect tower heat pulse state.
- A player loses when enemies breach and uses two-finger tap to immediately restart.

## Change log
- **v0.002:** Added explicit I/O framing and examples; aligned language with instruction-set baseline.
