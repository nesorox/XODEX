extends Node

const LEVEL_SCENE := "res://scenes/level_scene.tscn"
const MAIN_MENU_SCENE := "res://scenes/MainMenu.tscn"
const MIN_LEVEL_INDEX := 0
const MAX_LEVEL_INDEX := 1000

var level_index := 0
var run_seed := 0
var seed_label := "AUTO"

func start_new_run(seed_input: String = "") -> void:
	level_index = MIN_LEVEL_INDEX
	seed_label = _normalize_seed(seed_input)
	run_seed = _hash_seed(seed_label)
	_load_level_scene()

func retry_level() -> void:
	_load_level_scene()

func next_level() -> void:
	if level_index < MAX_LEVEL_INDEX:
		level_index += 1
	else:
		level_index = MIN_LEVEL_INDEX
		run_seed = _hash_seed("%s-%d" % [seed_label, Time.get_unix_time_from_system()])
	_load_level_scene()

func return_to_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func get_level_config() -> Dictionary:
	var normalized_level := clamp(level_index, MIN_LEVEL_INDEX, MAX_LEVEL_INDEX)
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed + normalized_level * 101
	var pattern := int(rng.randi_range(0, 4))
	var wave_count := _wave_count_for_level(normalized_level)
	var enemies_per_wave := _enemies_per_wave_for_level(normalized_level, rng)
	var enemy_speed := _enemy_speed_for_level(normalized_level, rng)
	var path_points := _build_path(pattern, rng)
	var map_mutation := _build_map_mutation(normalized_level, rng)
	var layout_profile := _build_layout_profile(normalized_level, rng)

	return {
		"level_index": normalized_level,
		"seed": run_seed,
		"seed_label": seed_label,
		"max_level_index": MAX_LEVEL_INDEX,
		"pattern": pattern,
		"wave_count": wave_count,
		"enemies_per_wave": enemies_per_wave,
		"enemy_speed": enemy_speed,
		"path_points": path_points,
		"map_mutation": map_mutation,
		"layout_profile": layout_profile,
	}

func _normalize_seed(seed_input: String) -> String:
	var cleaned := seed_input.strip_edges()
	if cleaned.is_empty():
		return "AUTO-%d" % randi()
	return cleaned

func _hash_seed(seed_string: String) -> int:
	var hash := 0
	for i in range(seed_string.length()):
		hash = ((hash << 5) - hash + seed_string.unicode_at(i)) & 0x7fffffff
	if hash == 0:
		hash = 1
	return hash

func _wave_count_for_level(next_level_index: int) -> int:
	return clamp(2 + int(next_level_index / 180), 2, 8)

func _enemies_per_wave_for_level(next_level_index: int, rng: RandomNumberGenerator) -> int:
	var tier_bonus := int(next_level_index / 45)
	var seeded_variation := int(rng.randi_range(0, 8))
	return clamp(6 + tier_bonus + seeded_variation, 6, 42)

func _enemy_speed_for_level(next_level_index: int, rng: RandomNumberGenerator) -> float:
	var seeded_variation := rng.randf_range(-8.0, 8.0)
	return 105.0 + float(next_level_index) * 0.55 + seeded_variation

func _build_layout_profile(next_level_index: int, rng: RandomNumberGenerator) -> Dictionary:
	return {
		"wall_density": rng.randf_range(0.20, 0.40),
		"tower_node_count": int(rng.randi_range(4, 8)),
		"thermal_zone_bias": rng.randf_range(0.7, 1.4),
		"vector_flow_bias": rng.randf_range(-1.0, 1.0),
		"resource_multiplier": 1.0 + float(next_level_index) * 0.001,
	}

func _load_level_scene() -> void:
	get_tree().change_scene_to_file(LEVEL_SCENE)

func _build_path(pattern: int, rng: RandomNumberGenerator) -> PackedVector2Array:
	match pattern:
		0:
			return _path_straight(rng)
		1:
			return _path_zigzag(rng)
		2:
			return _path_s_curve(rng)
		3:
			return _path_two_bends(rng)
		_:
			return _path_stepped(rng)

func _path_straight(rng: RandomNumberGenerator) -> PackedVector2Array:
	var mid_y := rng.randf_range(500.0, 780.0)
	return PackedVector2Array([
		Vector2(40.0, mid_y),
		Vector2(680.0, mid_y),
	])

func _path_zigzag(rng: RandomNumberGenerator) -> PackedVector2Array:
	var y0 := rng.randf_range(460.0, 820.0)
	var y1 := clamp(y0 - rng.randf_range(160.0, 240.0), 260.0, 980.0)
	var y2 := clamp(y1 + rng.randf_range(180.0, 280.0), 260.0, 980.0)
	return PackedVector2Array([
		Vector2(40.0, y0),
		Vector2(220.0, y1),
		Vector2(430.0, y2),
		Vector2(680.0, y1),
	])

func _path_s_curve(rng: RandomNumberGenerator) -> PackedVector2Array:
	var top := rng.randf_range(300.0, 500.0)
	var mid := rng.randf_range(560.0, 760.0)
	var low := clamp(mid + rng.randf_range(170.0, 260.0), 760.0, 1040.0)
	return PackedVector2Array([
		Vector2(40.0, mid),
		Vector2(190.0, top),
		Vector2(360.0, mid),
		Vector2(540.0, low),
		Vector2(680.0, mid),
	])

func _path_two_bends(rng: RandomNumberGenerator) -> PackedVector2Array:
	var first := rng.randf_range(350.0, 560.0)
	var second := clamp(first + rng.randf_range(220.0, 320.0), 520.0, 980.0)
	return PackedVector2Array([
		Vector2(40.0, first),
		Vector2(170.0, first),
		Vector2(260.0, second),
		Vector2(500.0, second),
		Vector2(680.0, first),
	])

func _path_stepped(rng: RandomNumberGenerator) -> PackedVector2Array:
	var lane_a := rng.randf_range(360.0, 520.0)
	var lane_b := clamp(lane_a + rng.randf_range(170.0, 250.0), 520.0, 900.0)
	var lane_c := clamp(lane_b - rng.randf_range(110.0, 190.0), 360.0, 760.0)
	return PackedVector2Array([
		Vector2(40.0, lane_a),
		Vector2(170.0, lane_a),
		Vector2(300.0, lane_b),
		Vector2(450.0, lane_b),
		Vector2(570.0, lane_c),
		Vector2(680.0, lane_c),
	])

func _build_map_mutation(next_level_index: int, rng: RandomNumberGenerator) -> Dictionary:
	var map_presets := [
		{
			"map_name": "AngelPressureField",
			"heat_global_multiplier": 1.2,
			"enemy_scaling_exponent": 1.3,
			"fog_density": 0.2,
			"heat_feedback_gain": 0.26,
			"heat_decay_coefficient": 0.24,
		},
		{
			"map_name": "DotAFlowDenial",
			"heat_global_multiplier": 1.05,
			"enemy_scaling_exponent": 1.15,
			"fog_density": 0.34,
			"heat_feedback_gain": 0.2,
			"heat_decay_coefficient": 0.2,
		},
		{
			"map_name": "TwilightRuleRegion",
			"heat_global_multiplier": 0.95,
			"enemy_scaling_exponent": 1.2,
			"fog_density": 0.45,
			"heat_feedback_gain": 0.16,
			"heat_decay_coefficient": 0.12,
		},
		{
			"map_name": "MafiaHiddenInvariant",
			"heat_global_multiplier": 1.1,
			"enemy_scaling_exponent": 1.25,
			"fog_density": 0.55,
			"heat_feedback_gain": 0.22,
			"heat_decay_coefficient": 0.16,
		},
	]
	var index := int(rng.randi_range(0, map_presets.size() - 1))
	var selected := map_presets[index].duplicate(true)
	var progression_gain := 1.0 + float(next_level_index) * 0.02
	selected["enemy_scaling_exponent"] *= progression_gain
	selected["heat_global_multiplier"] *= 1.0 + float(next_level_index) * 0.01
	return selected
