"""Regression checks for BURZEN TD v0.00.1 thermal simulation behavior."""

import unittest

from simulation.thermal_reference import (
    ThermalParams,
    apply_wasmutable_shift,
    simulate_heat_curve,
)


class ThermalReferenceTests(unittest.TestCase):
    """Validate canonical thermal mechanics used by simulation and release docs."""

    def test_overheat_and_recovery_transitions(self) -> None:
        params = ThermalParams()
        timeline = [True] * 8 + [False] * 25
        curve = simulate_heat_curve(timeline, dt=0.2, params=params)

        self.assertTrue(any(state.overheated for state in curve), "tower should overheat")
        self.assertFalse(curve[-1].overheated, "tower should recover after cooling")
        self.assertLessEqual(curve[-1].heat, params.recovery_threshold)

    def test_wasmutable_shift_increases_thermal_pressure(self) -> None:
        baseline = ThermalParams()
        shifted = apply_wasmutable_shift(baseline, shift_factor=1.35)

        self.assertGreater(shifted.heat_per_shot, baseline.heat_per_shot)
        self.assertLess(shifted.dissipation_rate, baseline.dissipation_rate)


if __name__ == "__main__":
    unittest.main()
