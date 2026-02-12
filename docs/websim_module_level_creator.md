# BURZEN Tower Defense – WebSim Module Level Creator

## Version
- Document version: **CODEX v0.001**
- Project target: **BURZEN Tower Defense module-level design workflow**

## Platform goal
WebSim is the interactive sandbox for constructing, testing, and iterating individual BURZEN TD levels. It is positioned as a **module-level simulator** where designers control geometry, tower affordances, wave streams, and mutable environmental rules while preserving the GROK-inspired learning loop of consequence-driven simulation.

## I. Platform context
WebSim is intentionally non-static. It should support:

- Dynamic grid-based maps with thermal and vector overlays.
- Interactive tower placement that can recalibrate creep paths in real time.
- Wave streaming capacity for approximately 100–500 mobs per level module.
- GROK logic overlays that visualize influence, flow, and heat stress.

All interactions are sandboxed around cause/effect simulation feedback, not precompiled puzzle answers.

## II. Level module structure
Each level module is self-contained and includes five interoperable layers:

### 1) Terrain grid
- Discrete blocks with properties (passable, traversal cost, thermal conductivity).
- Walls/obstacles define maze corridors.
- Tiles can encode extra physics metadata (slope, vector flow, material fatigue).

### 2) Tower nodes
- Predefined placements and/or constrained free-placement zones.
- Node roles such as `HeatSink`, `FlowRedirector`, and `EntropyAmplifier`.
- Towers create high-cost influence zones that alter creep routing.

### 3) Creep streams
- Wave configuration includes spawn points, count, base HP, speed, and creep type.
- Streams react to tower placement through dynamic path recalculation.
- Optional behavior traits include swarm cohesion, adaptive speed, and priority targeting.

### 4) Rule triggers (WASMUTABLE layer)
- Dynamic events such as overheat cascades, local cost inversion, and spawn escalation.
- Trigger styles can be time-based, tile-based, or player-activated.
- Designed to keep modules reactive rather than fixed.

### 5) Thermal and vector overlays
- Visual diagnostics for heat accumulation, energy flow, and creep pressure.
- Supports level balancing and rapid debugging.

## III. Map creator dynamics
WebSim modules are modular, interactive, and mutable.

### Walled structures
- Walls define high-cost boundaries and corridors.
- They can funnel, split, or delay creep streams.
- Segments may degrade or shift behavior under thermal pressure.

### Open terrain
- Supports multi-route path possibility.
- Encourages chokepoint and branch experimentation.

### Dynamic costs
- Tower influence and thermal events modify local traversal costs.
- Mobs continuously seek updated optimal routes to produce natural maze dynamics.

### Special zones
- Slope, heat, and temporal tiles introduce environmental complexity.
- Can model scarcity pressure, efficiency decay, and entropy amplification.

## IV. System settings for level design

| Category | Settings | Function |
| --- | --- | --- |
| Grid | Size, tile type, wall placement | Defines physical constraints |
| Towers | Available types, initial positions, upgrade limits | Defines strategic options |
| Creeps | Spawn points, wave count, HP/speed scaling | Defines baseline challenge |
| Wave streams | Interval, composition, special behavior flags | Defines pressure cadence |
| Thermal field | Heat accumulation and dissipation rates | Alters tower output and route pressure |
| WASMUTABLE rules | Overheat events, cost inversions, escalation switches | Injects dynamic mutation logic |
| Visual feedback | Vector overlays, thermal coloring, pressure cues | Makes balancing and diagnostics legible |

## V. Module creation workflow
1. **Define grid and map layout**  
   Place walls/obstacles to shape corridors, chokepoints, and open sectors.
2. **Set tower zones**  
   Configure fixed nodes and/or constrained free-placement regions.
3. **Configure waves**  
   Author creep types, quantities, HP, speed, and progression scaling.
4. **Activate WASMUTABLE triggers**  
   Bind runtime mutations to timers, tiles, and player actions.
5. **Run simulation**  
   Observe damage throughput, path adaptation, and thermal behavior.
6. **Iterate**  
   Adjust walls, nodes, wave mix, and rules to refine emergent balance.

## VI. Educational and game-design outcomes
WebSim modules should enable designers to:

- Prototype levels quickly with placeholder geometry.
- Test interactions across towers, thermal pressure, route adaptation, and wave scaling.
- Experiment with mutable rules and cost-field transformations.
- Visualize abstract systems (vector flow, energy distribution, thermal stress) through clear overlays.

The intended learning loop is consequence-first: players and designers infer logic through outcomes rather than explicit instruction text.
