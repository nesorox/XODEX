"""Reference thermal model for BURZEN TD v0.00.1.

This file defines the source-of-truth heat behavior used to tune
and verify engine-side implementation.
"""

from __future__ import annotations

from dataclasses import dataclass, replace
from typing import Iterable, List


@dataclass(frozen=True)
class ThermalParams:
    capacity: float = 100.0
    heat_per_shot: float = 18.0
    dissipation_rate: float = 14.0
    recovery_threshold_ratio: float = 0.45

    @property
    def recovery_threshold(self) -> float:
        return self.capacity * self.recovery_threshold_ratio


@dataclass
class TowerThermalState:
    heat: float = 0.0
    overheated: bool = False

    def step(self, dt: float, fired: bool, params: ThermalParams) -> None:
        self.heat = max(0.0, self.heat - params.dissipation_rate * dt)

        if fired and not self.overheated:
            self.heat += params.heat_per_shot

        if not self.overheated and self.heat >= params.capacity:
            self.overheated = True
        elif self.overheated and self.heat <= params.recovery_threshold:
            self.overheated = False


def simulate_heat_curve(
    fire_timeline: Iterable[bool], dt: float, params: ThermalParams | None = None
) -> List[TowerThermalState]:
    active_params = params or ThermalParams()
    state = TowerThermalState()
    out: List[TowerThermalState] = []
    for fired in fire_timeline:
        state.step(dt=dt, fired=fired, params=active_params)
        out.append(TowerThermalState(heat=state.heat, overheated=state.overheated))
    return out


def apply_wasmutable_shift(params: ThermalParams, *, shift_factor: float) -> ThermalParams:
    """Return a mutated thermal profile for recursive refinement experiments.

    `shift_factor > 1` increases volatility and punishes high fire cadence.
    """

    return replace(
        params,
        heat_per_shot=params.heat_per_shot * shift_factor,
        dissipation_rate=max(0.1, params.dissipation_rate / shift_factor),
    )


def _demo() -> None:
    dt = 0.2
    baseline = ThermalParams()
    aggressive_firing = [True] * 25 + [False] * 40

    baseline_curve = simulate_heat_curve(aggressive_firing, dt, baseline)
    shifted_curve = simulate_heat_curve(
        aggressive_firing,
        dt,
        apply_wasmutable_shift(baseline, shift_factor=1.35),
    )

    print("BASELINE:")
    for i, s in enumerate(baseline_curve[:12]):
        print(f"t={i*dt:>4.1f}s heat={s.heat:>6.2f} overheated={s.overheated}")

    print("\nSHIFTED:")
    for i, s in enumerate(shifted_curve[:12]):
        print(f"t={i*dt:>4.1f}s heat={s.heat:>6.2f} overheated={s.overheated}")


if __name__ == "__main__":
    _demo()
