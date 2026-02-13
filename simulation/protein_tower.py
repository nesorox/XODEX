"""Reference simulation model for XODEX.PROTEIN_TOWER.

This module includes:
- single-tower geometry-resolving field behavior,
- multi-tower pattern synthesis and coupling,
- cross-domain integration with Token-Tower priors.
"""

from __future__ import annotations

from dataclasses import dataclass
from math import dist
from typing import Iterable, Sequence


Grid = Sequence[Sequence[float]]


@dataclass(frozen=True)
class ProteinTowerConfig:
    footprint_tiles: tuple[int, int] = (2, 2)
    min_radius_tiles: int = 6
    max_radius_tiles: int = 8
    local_sample_size: int = 8
    alpha_0: float = 1.0
    alpha_wave_scale: float = 0.08
    base_adaptation_rate: float = 0.22
    adaptation_decay_per_wave: float = 0.01
    min_adaptation_rate: float = 0.05
    heat_per_tick: float = 0.7
    heat_decay_per_tick: float = 0.2
    instability_threshold: float = 12.0


@dataclass(frozen=True)
class ProteinTowerState:
    theta: float = 0.5
    heat: float = 0.0
    collapsed: bool = False


@dataclass(frozen=True)
class TokenTowerState:
    path_probability_bias: float = 0.5
    prediction_depth: int = 3


@dataclass(frozen=True)
class LocalFlowState:
    creep_density: Grid
    flow_speed: Grid
    wall_block: Grid


@dataclass(frozen=True)
class ProteinTickResult:
    state: ProteinTowerState
    disruption_field: float
    curvature: float
    damage: float


@dataclass(frozen=True)
class TowerPlacement:
    x: int
    y: int


@dataclass(frozen=True)
class ProteinPatternSummary:
    chain_count: int
    lattice_count: int
    ring_count: int
    fiber_bundle_active: bool


def alpha_for_wave(wave_index: int, config: ProteinTowerConfig) -> float:
    return config.alpha_0 * (1.0 + config.alpha_wave_scale * max(0, wave_index))


def adaptation_rate_for_wave(wave_index: int, config: ProteinTowerConfig) -> float:
    return max(
        config.min_adaptation_rate,
        config.base_adaptation_rate - config.adaptation_decay_per_wave * max(0, wave_index),
    )


def _mean(grid: Grid) -> float:
    flat = [value for row in grid for value in row]
    return sum(flat) / max(1, len(flat))


def _center_laplacian(grid: Grid) -> float:
    rows = len(grid)
    cols = len(grid[0]) if rows else 0
    if rows < 3 or cols < 3:
        return 0.0
    cx = rows // 2
    cy = cols // 2
    center = grid[cx][cy]
    north = grid[cx - 1][cy]
    south = grid[cx + 1][cy]
    west = grid[cx][cy - 1]
    east = grid[cx][cy + 1]
    return north + south + west + east - 4.0 * center


def _compute_disruption_field(state: ProteinTowerState, local_flow: LocalFlowState) -> float:
    density = _mean(local_flow.creep_density)
    speed = _mean(local_flow.flow_speed)
    wall = _mean(local_flow.wall_block)
    return state.theta * (1.5 * density + 0.6 * speed + 0.4 * wall)


def _update_theta(
    theta: float,
    adaptation_rate: float,
    predicted_disruption: float,
    realized_escape_energy: float,
) -> float:
    error = predicted_disruption - realized_escape_energy
    return max(0.0, theta + adaptation_rate * error)


def step_protein_tower(
    state: ProteinTowerState,
    local_flow: LocalFlowState,
    wave_index: int,
    realized_escape_energy: float,
    config: ProteinTowerConfig = ProteinTowerConfig(),
) -> ProteinTickResult:
    """Run one mutable Protein Tower update tick."""

    if state.collapsed:
        cooled = max(0.0, state.heat - config.heat_decay_per_tick)
        recovered = cooled < config.instability_threshold * 0.5
        next_state = ProteinTowerState(theta=state.theta, heat=cooled, collapsed=not recovered)
        return ProteinTickResult(state=next_state, disruption_field=0.0, curvature=0.0, damage=0.0)

    disruption_field = _compute_disruption_field(state, local_flow)
    curvature = abs(_center_laplacian(local_flow.creep_density))
    damage = alpha_for_wave(wave_index, config) * curvature * disruption_field

    adaptation_rate = adaptation_rate_for_wave(wave_index, config)
    next_theta = _update_theta(state.theta, adaptation_rate, disruption_field, realized_escape_energy)

    next_heat = max(0.0, state.heat + config.heat_per_tick * disruption_field - config.heat_decay_per_tick)
    collapsed = next_heat > config.instability_threshold

    next_state = ProteinTowerState(theta=next_theta, heat=next_heat, collapsed=collapsed)
    return ProteinTickResult(
        state=next_state,
        disruption_field=disruption_field,
        curvature=curvature,
        damage=0.0 if collapsed else damage,
    )


def _adjacent(a: TowerPlacement, b: TowerPlacement) -> bool:
    return max(abs(a.x - b.x), abs(a.y - b.y)) <= 1


def detect_protein_patterns(placements: Sequence[TowerPlacement]) -> ProteinPatternSummary:
    """Detect chain/lattice/ring and fiber-bundle flags for Protein tower groups."""

    points = {(p.x, p.y) for p in placements}

    chain_count = 0
    for p in placements:
        horizontal = ((p.x - 1, p.y) in points and (p.x + 1, p.y) in points)
        vertical = ((p.x, p.y - 1) in points and (p.x, p.y + 1) in points)
        diagonal = ((p.x - 1, p.y - 1) in points and (p.x + 1, p.y + 1) in points) or (
            (p.x - 1, p.y + 1) in points and (p.x + 1, p.y - 1) in points
        )
        if horizontal or vertical or diagonal:
            chain_count += 1

    lattice_count = 0
    for x, y in points:
        if {(x, y), (x + 1, y), (x, y + 1), (x + 1, y + 1)}.issubset(points):
            lattice_count += 1

    ring_count = 0
    for x, y in points:
        if {(x, y), (x + 2, y), (x, y + 2), (x + 2, y + 2)}.issubset(points):
            ring_count += 1

    rows = sorted({p.y for p in placements})
    fiber_bundle_active = len(rows) >= 2 and any(0 < (b - a) <= 2 for a, b in zip(rows, rows[1:])) and chain_count >= 2

    return ProteinPatternSummary(
        chain_count=chain_count,
        lattice_count=lattice_count,
        ring_count=ring_count,
        fiber_bundle_active=fiber_bundle_active,
    )


def synthesize_protein_cluster(
    tower_states: Sequence[ProteinTowerState],
    placements: Sequence[TowerPlacement],
    coupling_eta: float = 0.08,
    coupling_range_tiles: float = 3.0,
    coupling_heat_gain: float = 0.15,
) -> list[ProteinTowerState]:
    """Gradient-sharing update: Theta_i <- Theta_i + eta*(Theta_j - Theta_i)."""

    next_states: list[ProteinTowerState] = []
    for i, state_i in enumerate(tower_states):
        blended_theta = state_i.theta
        neighbors = 0
        for j, state_j in enumerate(tower_states):
            if i == j:
                continue
            if dist((placements[i].x, placements[i].y), (placements[j].x, placements[j].y)) <= coupling_range_tiles:
                blended_theta += coupling_eta * (state_j.theta - state_i.theta)
                neighbors += 1
        heat_delta = coupling_heat_gain * neighbors
        next_states.append(
            ProteinTowerState(
                theta=max(0.0, blended_theta),
                heat=state_i.heat + heat_delta,
                collapsed=state_i.collapsed,
            )
        )
    return next_states


def apply_pattern_field_multiplier(base_field: float, summary: ProteinPatternSummary) -> float:
    """Composite field multiplier for chain/lattice/ring/fiber synthesis."""

    chain_boost = 0.10 * summary.chain_count
    lattice_boost = 0.25 * summary.lattice_count
    ring_boost = 0.18 * summary.ring_count
    bundle_boost = 0.30 if summary.fiber_bundle_active else 0.0
    return base_field * (1.0 + chain_boost + lattice_boost + ring_boost + bundle_boost)


def token_cross_domain_field(
    protein_field: float,
    token_towers: Iterable[TokenTowerState],
    lambda_coupling: float = 0.35,
) -> float:
    """x† = argmin(E + Psi + Lambda*P) approximated as scalar field composition."""

    token_list = list(token_towers)
    if not token_list:
        return protein_field
    prediction_prior = sum(t.path_probability_bias for t in token_list) / len(token_list)
    depth_bonus = sum(t.prediction_depth for t in token_list) / max(1, len(token_list))
    return protein_field + lambda_coupling * prediction_prior * (1.0 + 0.05 * depth_bonus)


def synthesis_hub_adjustment(
    protein_state: ProteinTowerState,
    adjacent_token_towers: Sequence[TokenTowerState],
) -> ProteinTowerState:
    """Central protein + 3-6 token towers: rapid adaptation and reduced heat volatility."""

    count = len(adjacent_token_towers)
    if count < 3:
        return protein_state
    count = min(count, 6)
    theta_gain = 0.04 * count
    heat_reduction = 0.1 * count
    return ProteinTowerState(
        theta=protein_state.theta + theta_gain,
        heat=max(0.0, protein_state.heat - heat_reduction),
        collapsed=protein_state.collapsed,
    )


def overcoupled_cluster_collapsed(tower_states: Sequence[ProteinTowerState], theta_critical: float) -> bool:
    """Resonance instability guard: collapse when sum(Theta) exceeds threshold."""

    return sum(state.theta for state in tower_states) > theta_critical
