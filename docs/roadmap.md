# Roadmap

## Version
- Document version: **CODEX v0.004**

## Purpose & justification
Tracks milestone progression from prototype baseline into a replayable shell and then rule-engine integration.

## Input / output behavior
- **Inputs:** roadmap milestone definition, accepted feature specs, release test status.
- **Outputs:** versioned development targets with success criteria alignment.

## Milestones
### v0.00.2
- Scope: Main menu entry, level manager, procedural path variants, and wave/lives progression loop.
- Success criteria:
  - App launches into landing page instead of direct gameplay.
  - Play flow enters gameplay with seeded/random route generation.
  - At least 3 distinct procedural path variants are selectable/generated.
  - Win/loss states support retry/next/menu transitions.

### v0.00.3
- Scope: Expand map mutation runtime with visible vector-flow and entropy overlays.
- Success criteria: pressure fields and hidden-cost hints are legible without obscuring touch controls.

### v0.00.4
- Scope: Adaptive enemies with dynamic route biasing and denial pockets.
- Success criteria: enemy route choices and map denial zones shift in response to tower pressure.

### v0.01.0
- Scope: Player-authored WASMUTABLE overlays (safe mid-run parameter mutation).
- Success criteria: mutation interfaces are deterministic, bounded, and exportable to map config.

## Change log
- **v0.004:** Added Layer-02 map-mutation pressure runtime direction and aligned downstream milestones with editable-universe progression.
- **v0.003:** Added replayable-shell milestone details for v0.00.2 and shifted downstream milestones.
