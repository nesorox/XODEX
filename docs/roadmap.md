# Roadmap

## Version
- Document version: **CODEX v0.003**

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
- Scope: Vector flow visualization for path pressure legibility.
- Success criteria: visual flow cues are visible and non-invasive to touch controls.

### v0.00.4
- Scope: Adaptive enemies with dynamic route biasing.
- Success criteria: enemy route choices change in response to tower placement pressure.

### v0.01.0
- Scope: WASMUTABLE rule shifts (mid-run parameter mutation).
- Success criteria: rule-engine parameter mutation is safe, deterministic, and documented.

## Change log
- **v0.003:** Added replayable-shell milestone details for v0.00.2 and shifted downstream milestones.
