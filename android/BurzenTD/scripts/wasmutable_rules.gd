extends RefCounted

class_name WasmutableRules

var thermal_profile := {
	"capacity": 100.0,
	"heat_per_shot": 18.0,
	"dissipation_rate": 14.0,
	"recovery_ratio": 0.45,
}

func reset_to_defaults(default_profile: Dictionary) -> void:
	thermal_profile = default_profile.duplicate(true)

func mutate_for_pressure_cycle(factor: float) -> Dictionary:
	var next_profile = thermal_profile.duplicate(true)
	next_profile["heat_per_shot"] *= factor
	next_profile["dissipation_rate"] = max(0.1, next_profile["dissipation_rate"] / factor)
	thermal_profile = next_profile
	return thermal_profile
