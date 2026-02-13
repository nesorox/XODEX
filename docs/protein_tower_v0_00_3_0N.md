# XODEX.PROTEIN_TOWER — BURZEN TD v0.00.3.0(N)

## System classification
- **Tower type:** Adaptive Structural Resolver
- **Footprint:** 2×2 tiles
- **Domain role:** Geometry prediction under energy constraints
- **Version:** v0.00.3.0(N)

The Protein Tower is constrained function approximation over local creep geometry, not linear raw DPS scaling.

## Single-tower formal mapping
- Protein-folding analog: `s -> x*`
- TD reinterpretation: `Phi_t -> Psi*`
  - `Phi_t`: local creep distribution tensor
  - `Psi*`: optimized disruption field minimizing creep escape energy

### Tick model
Each tick:
1. Sample local 8×8 neighborhood.
2. Encode pairwise creep relationships in mutable `Theta`.
3. Estimate local energy manifold.
4. Apply perturbation field.

Primary outcomes: path bending, speed modulation, localized damage over time, and heat redistribution.

### Damage + adaptation
- Emergent damage: `D = alpha * Laplacian(Psi)`
- Parameter update: `Theta_(t+1) = Theta_t + eta * Delta`
- Wave scaling: `alpha_w = alpha_0 * (1 + 0.08w)`
- Instability: heat threshold can force temporary field collapse.

---

## Pattern synthesis & multi-tower structural coupling

Multiple Protein Towers can form deterministic Coupled Structural Field Systems (CSFS).

### Pattern class 1: Linear chain (filament)
**Condition:** three or more Protein Towers aligned orthogonally or diagonally adjacent.

**Composite field:** `Psi_chain = sum(Psi_i) + beta * grad_parallel`

**Effects:** directional bending boost, stronger slow, faster axis heat accumulation.

### Pattern class 2: Lattice (grid coupling)
**Condition:** four Protein Towers in a square macro arrangement.

**Composite field:** `Psi_lattice = sum(Psi_i) + gamma * Laplacian(Psi)`

**Effects:** stronger swarm destabilization and distributed AoE with better adaptation stability.

### Pattern class 3: Ring (closed loop)
**Condition:** Protein Towers form a closed geometric loop.

**Constraint:** closed-circulation field (`integral(Psi dx) != 0`).

**Effects:** velocity dampening inside loop, heat recirculation, stability increase.

---

## Protein synthesis (distributed gradient sharing)

Each Protein Tower exposes:
- local tensor state,
- adaptation gradient,
- heat scalar.

For neighbors within <= 3 tiles:

`Theta_i <- Theta_i + eta * (Theta_j - Theta_i)`

This accelerates convergence for tower clusters while increasing coupled heat load.

---

## Fiber bundle mode (chain-linked muscle system)

When linear chains run in parallel with spacing <= 2 tiles, Fiber Bundle mode activates.

`Psi_bundle = sum(Psi_chain) + delta * cohesion`

**Effects:** stronger displacement force, elevated knockback likelihood, density-threshold burst pressure.

---

## XODEX.TOKEN_TOWER and cross-domain linkage

Token Tower models creep movement as sequence prediction:

`P(w_t | w_<t)`

It predicts likely next path transitions in discrete space and does not replace geometric field modeling.

When adjacent to Protein cluster:

`x† = argmin(E(x) + Psi(x) + Lambda*P(x))`

Result: prediction-informed geometric distortion, stronger fast-creep handling, earlier-wave stabilization.

---

## Advanced synthesis hub

**Configuration:** central Protein Tower with 3–6 Token Towers.

`Psi_hub = F(Phi_t, P_t)` where `P_t` is aggregated token priors.

**Effects:** faster adaptation, lower heat volatility, higher swarm suppression consistency.

---

## Instability and balance guards

- Over-coupling resonance guard: collapse when `sum(Theta) > Theta_critical`.
- Protein constraints: radius bounded to 6–8 tiles, dense-swarm dependency, heat instability thresholds.
- Token/Protein interaction remains deterministic and bounded inside system rules.

---

## Reference implementation mapping
`simulation/protein_tower.py` includes:
- single tower runtime (`step_protein_tower`),
- pattern detection (`detect_protein_patterns`),
- cluster synthesis (`synthesize_protein_cluster`),
- composite field scaling (`apply_pattern_field_multiplier`),
- token cross-domain coupling (`token_cross_domain_field`),
- synthesis hub adjustment + over-coupling guard.
