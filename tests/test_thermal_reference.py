import unittest

from simulation.thermal_reference import (
    ThermalParams,
    apply_wasmutable_shift,
    simulate_heat_curve,
)


class ThermalReferenceTests(unittest.TestCase):
    def test_overheat_occurs_under_sustained_fire(self) -> None:
        curve = simulate_heat_curve([True] * 12, dt=0.2, params=ThermalParams())
        self.assertTrue(any(s.overheated for s in curve))

    def test_recovery_occurs_after_cooldown(self) -> None:
        timeline = [True] * 12 + [False] * 40
        curve = simulate_heat_curve(timeline, dt=0.2, params=ThermalParams())
        self.assertTrue(curve[11].overheated)
        self.assertFalse(curve[-1].overheated)

    def test_wasmutable_shift_increases_thermal_pressure(self) -> None:
        baseline = ThermalParams()
        shifted = apply_wasmutable_shift(baseline, shift_factor=1.25)
        self.assertGreater(shifted.heat_per_shot, baseline.heat_per_shot)
        self.assertLess(shifted.dissipation_rate, baseline.dissipation_rate)


if __name__ == "__main__":
    unittest.main()
