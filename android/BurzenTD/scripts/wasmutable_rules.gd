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

var active_event := {
	"name": "",
	"remaining": 0.0,
	"tower_heat_multiplier": 1.0,
	"tower_damage_multiplier": 1.0,
	"enemy_speed_multiplier": 1.0,
	"energy_tick_multiplier": 1.0,
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
	speed_scale *= active_event.get("enemy_speed_multiplier", 1.0)
	return clamp(base_speed * speed_scale, base_speed * 0.85, base_speed * 2.4)

func sample_wave_event(rng: RandomNumberGenerator, wave_progress: float) -> Dictionary:
	if active_event.get("remaining", 0.0) > 0.0:
		return active_event
	if wave_progress < 0.2 or rng.randf() > 0.015:
		return active_event

	var pool := [
		{
			"name": "Cost Inversion",
			"remaining": 8.0,
			"tower_heat_multiplier": 0.85,
			"tower_damage_multiplier": 0.9,
			"enemy_speed_multiplier": 1.1,
			"energy_tick_multiplier": 1.25,
		},
		{
			"name": "Overheat Spike",
			"remaining": 6.0,
			"tower_heat_multiplier": 1.35,
			"tower_damage_multiplier": 1.0,
			"enemy_speed_multiplier": 1.0,
			"energy_tick_multiplier": 0.8,
		},
		{
			"name": "Spawn Drift",
			"remaining": 10.0,
			"tower_heat_multiplier": 1.0,
			"tower_damage_multiplier": 0.8,
			"enemy_speed_multiplier": 1.2,
			"energy_tick_multiplier": 1.1,
		},
	]
	active_event = pool[int(rng.randi_range(0, pool.size() - 1))].duplicate(true)
	return active_event

func update_event(delta: float) -> Dictionary:
	if active_event.get("remaining", 0.0) <= 0.0:
		active_event = {
			"name": "",
			"remaining": 0.0,
			"tower_heat_multiplier": 1.0,
			"tower_damage_multiplier": 1.0,
			"enemy_speed_multiplier": 1.0,
			"energy_tick_multiplier": 1.0,
		}
		return active_event
	active_event["remaining"] = max(0.0, active_event["remaining"] - delta)
	if active_event["remaining"] <= 0.0:
		active_event["name"] = ""
	return active_event
