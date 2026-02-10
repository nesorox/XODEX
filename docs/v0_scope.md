# v0.00.1 Scope Lock

## Version
- Document version: **CODEX v0.002**
- Scope target: **BURZEN Tower Defense v0.00.1**

## Purpose & justification
Defines canonical in-scope and out-of-scope boundaries so releases stay prototype-focused and auditable.

## Input / output behavior
- **Inputs:** source updates, build invocation, gameplay touch interactions.
- **Outputs:** reproducible APK artifact, stable baseline simulation behavior, clear exclusion boundaries.

## Included
- Android APK export target
- Single playable map
- Enemy spawn and left-to-right movement baseline
- Tap-to-place towers (max 5)
- Tower fire with heat/capacity/dissipation logic
- Overheat lockout behavior
- Enemy breach fail state
- Restart loop via tap/two-finger tap
- Long-press heat highlight

## Excluded
- Menus / settings / account systems
- Narrative and tutorial text in gameplay
- Progression economy
- Win-state campaign structure
- Cosmetic polish

## Hard constraints
- Offline-only
- Single-player
- Portrait orientation
- Touch-only controls

## Change log
- **v0.002:** Added formal version header, I/O behavior section, and scope wording aligned to instruction set.
