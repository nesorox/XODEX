# XODEX (BURZEN Tower Defense) - Roadmap

*Note: This is a temporary conceptual roadmap and does not reflect committed features.*

## Phase 1: Core Systems & Cleanup (Current)
- [x] Consolidate repository to only Godot runtime structure.
- [x] Establish strict AI context and system prompts in `README.md`.
- [ ] Finalize standard Enemy & Tower Base Classes (fully strict-typed).
- [ ] Implement robust Level Manager state machine (Pre-Wave -> Active -> Post-Wave).

## Phase 2: Tactical Overhaul & "Protein Interactions"
- [ ] **Tower Affinities**: Towers that touch buff one another depending on their defined "elements."
- [ ] **Heat/Residue Mechanics**: Towers generate heat when firing. High heat provides faster fire rate but risks short-term disabling. 
- [ ] **Dynamic Enemy Pathing**: Allow enemies to slightly detour or squeeze around tight tower placements rather than just following a single strict spline.

## Phase 3: Meta-Progression & Polish
- [ ] **Campaign UI Overhaul**: Smooth transitions between the world map and individual thermal extraction zones.
- [ ] **Save/Load System**: Persist unlocked tactical options and completed levels using a secure local save format.
- [ ] **Visual Polish**: Implement custom Godot 4 shaders for the heat distortion and residue visual effects.

---
*Roadmap is subject to heavy iteration.*
