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

func get_profile_copy() -> Dictionary:
	return thermal_profile.duplicate(true)

func mutate_for_pressure_cycle(factor: float) -> Dictionary:
	var safe_factor := _sanitize_factor(factor)
	var next_profile = thermal_profile.duplicate(true)
	next_profile["heat_per_shot"] *= safe_factor
	next_profile["dissipation_rate"] = max(0.1, next_profile["dissipation_rate"] / safe_factor)
	thermal_profile = next_profile
	return get_profile_copy()


func _sanitize_factor(factor: float) -> float:
	if factor <= 0.0:
		return 1.0
	return factor
