extends Node

const LEVEL_SCENE := "res://scenes/level_scene.tscn"
const MAIN_MENU_SCENE := "res://scenes/MainMenu.tscn"

var level_index := 0
var current_seed := 0

func start_new_run() -> void:
	level_index = 1
	current_seed = randi()
	_load_level_scene()

func retry_level() -> void:
	_load_level_scene()

func next_level() -> void:
	level_index += 1
	current_seed = randi()
	_load_level_scene()

func return_to_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func get_level_config() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = current_seed + level_index * 101
	var pattern := int(rng.randi_range(0, 4))
	var wave_count := clamp(2 + level_index, 2, 6)
	var enemies_per_wave := clamp(5 + level_index * 2, 5, 20)
	var enemy_speed := 105.0 + level_index * 10.0
	var path_points := _build_path(pattern, rng)
	var map_mutation := _build_map_mutation(level_index, rng)

	return {
		"level_index": level_index,
		"seed": current_seed,
		"pattern": pattern,
		"wave_count": wave_count,
		"enemies_per_wave": enemies_per_wave,
		"enemy_speed": enemy_speed,
		"path_points": path_points,
		"map_mutation": map_mutation,
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
	var progression_gain := 1.0 + float(next_level_index - 1) * 0.05
	selected["enemy_scaling_exponent"] *= progression_gain
	selected["heat_global_multiplier"] *= 1.0 + float(next_level_index - 1) * 0.02
	return selected
