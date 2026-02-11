extends RefCounted

class_name WasmutableRules

const DEFAULT_MAP_MUTATION := {
	"map_name": "BaselineInvariant",
	"heat_global_multiplier": 1.0,
	"enemy_scaling_exponent": 1.0,
	"fog_density": 0.0,
	"heat_feedback_gain": 0.18,
	"heat_decay_coefficient": 0.2,
}

var thermal_profile := {
	"capacity": 100.0,
	"heat_per_shot": 18.0,
	"dissipation_rate": 14.0,
	"recovery_ratio": 0.45,
}

var map_mutation := DEFAULT_MAP_MUTATION.duplicate(true)

func mutate_for_pressure_cycle(factor: float) -> Dictionary:
	var next_profile = thermal_profile.duplicate(true)
	next_profile["heat_per_shot"] *= factor
	next_profile["dissipation_rate"] = max(0.1, next_profile["dissipation_rate"] / factor)
	thermal_profile = next_profile
	return thermal_profile

func configure_map_mutation(next_map_mutation: Dictionary) -> Dictionary:
	map_mutation = DEFAULT_MAP_MUTATION.duplicate(true)
	for key in next_map_mutation.keys():
		map_mutation[key] = next_map_mutation[key]
	return map_mutation

func build_tower_thermal_profile() -> Dictionary:
	var profile := thermal_profile.duplicate(true)
	profile["heat_per_shot"] *= map_mutation.get("heat_global_multiplier", 1.0)
	profile["dissipation_rate"] = max(0.1, profile["dissipation_rate"] / map_mutation.get("heat_global_multiplier", 1.0))
	return profile

func compute_enemy_pressure_speed(base_speed: float, efficiency: float, global_heat: float) -> float:
	var exponent: float = map_mutation.get("enemy_scaling_exponent", 1.0)
	var heat_gain: float = map_mutation.get("heat_feedback_gain", 0.18)
	var clamped_efficiency := clamp(efficiency, 0.2, 7.5)
	var escalation := pow(clamped_efficiency, exponent)
	var speed_scale := 1.0 + (escalation - 1.0) * 0.16 + global_heat * heat_gain
	return clamp(base_speed * speed_scale, base_speed * 0.85, base_speed * 2.4)
