extends Node

const LEVEL_SCENE := "res://scenes/level_scene.tscn"
const MAIN_MENU_SCENE := "res://scenes/MainMenu.tscn"
const MIN_LEVEL_INDEX := 0
const MAX_LEVEL_INDEX := 1000
const SAVE_PATH := "user://single_player_progress.save"
const BOARD_SIZE := 80
const WALL_MIN_DENSITY := 0.15
const WALL_MAX_DENSITY := 0.35

var level_index := 0
var run_seed := 0
var seed_label := "AUTO"
var progress := {
	"waves_cleared": 0,
	"tower_upgrade_points": 0,
	"seed_history": [],
}

func _ready() -> void:
	_load_progress()

func start_new_run(seed_input: String = "") -> void:
	level_index = MIN_LEVEL_INDEX
	seed_label = _normalize_seed(seed_input)
	run_seed = _hash_seed(seed_label)
	_register_seed(seed_label)
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
	var normalized_level: int = clamp(level_index, MIN_LEVEL_INDEX, MAX_LEVEL_INDEX)
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed + normalized_level * 101
	var wave_count: int = _wave_count_for_level(normalized_level)
	var enemies_per_wave: int = _enemies_per_wave_for_level(normalized_level, rng)
	var enemy_speed: float = _enemy_speed_for_level(normalized_level, rng)
	var board_layout: Dictionary = _build_board_layout(normalized_level, rng)
	var map_mutation: Dictionary = _build_map_mutation(normalized_level, rng)
	var layout_profile: Dictionary = _build_layout_profile(normalized_level, rng, float(board_layout.get("wall_density", 0.2)))
	var wave_definition: Dictionary = _build_wave_definition(normalized_level, rng)
	var tower_nodes: Array[Vector2] = board_layout.get("tower_nodes", [])

	return {
		"level_index": normalized_level,
		"seed": run_seed,
		"seed_label": seed_label,
		"max_level_index": MAX_LEVEL_INDEX,
		"pattern": 0,
		"wave_count": wave_count,
		"enemies_per_wave": enemies_per_wave,
		"enemy_speed": enemy_speed,
		"path_tiles": board_layout.get("path_tiles", []),
		"walls": board_layout.get("walls", {}),
		"spawn_tile": board_layout.get("spawn_tile", Vector2i(0, 0)),
		"exit_tile": board_layout.get("exit_tile", Vector2i(79, 79)),
		"board_size": BOARD_SIZE,
		"map_mutation": map_mutation,
		"layout_profile": layout_profile,
		"wave_definition": wave_definition,
		"tower_nodes": tower_nodes,
		"progress": progress.duplicate(true),
	}

func record_wave_clear() -> void:
	progress["waves_cleared"] += 1
	if progress["waves_cleared"] % 2 == 0:
		progress["tower_upgrade_points"] += 1
	_save_progress()

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

func _build_layout_profile(next_level_index: int, rng: RandomNumberGenerator, wall_density: float) -> Dictionary:
	return {
		"wall_density": wall_density,
		"tower_node_count": int(rng.randi_range(4, 8)),
		"thermal_zone_bias": rng.randf_range(0.7, 1.4),
		"vector_flow_bias": rng.randf_range(-1.0, 1.0),
		"resource_multiplier": 1.0 + float(next_level_index) * 0.001,
	}

func _load_level_scene() -> void:
	get_tree().change_scene_to_file(LEVEL_SCENE)

func _register_seed(seed_value: String) -> void:
	var history: Array = progress.get("seed_history", [])
	if not history.has(seed_value):
		history.append(seed_value)
	progress["seed_history"] = history.slice(max(0, history.size() - 10), history.size())
	_save_progress()

func _build_wave_definition(next_level_index: int, rng: RandomNumberGenerator) -> Dictionary:
	var baseline: int = clamp(100 + int(next_level_index * 1.2), 100, 500)
	var creep_count: int = clamp(baseline + int(rng.randi_range(-18, 26)), 100, 500)
	return {
		"creep_count": creep_count,
		"spawn_batch": 3,
		"spawn_interval": clamp(0.18 - float(next_level_index) * 0.00009, 0.06, 0.18),
		"base_hp": 20.0 + float(next_level_index) * 0.85,
		"hp_step": 1.8,
		"speed_step": 4.0,
	}

func _build_tower_nodes(layout_profile: Dictionary, rng: RandomNumberGenerator) -> Array[Vector2]:
	return []

func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var data = file.get_var()
	if typeof(data) == TYPE_DICTIONARY:
		for key in data.keys():
			progress[key] = data[key]

func _save_progress() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_var(progress)

func _build_board_layout(next_level_index: int, rng: RandomNumberGenerator) -> Dictionary:
	var wall_density: float = clamp(rng.randf_range(WALL_MIN_DENSITY, WALL_MAX_DENSITY) + float(next_level_index) * 0.00005, WALL_MIN_DENSITY, WALL_MAX_DENSITY)
	var spawn_tile: Vector2i = _pick_edge_tile(rng, true)
	var exit_tile: Vector2i = _pick_edge_tile(rng, false)
	var path_tiles: Array[Vector2i] = _carve_seed_path(spawn_tile, exit_tile, rng)
	var path_set: Dictionary = {}
	for tile in path_tiles:
		path_set[_tile_key(tile)] = true

	var walls: Dictionary = {}
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			var tile := Vector2i(x, y)
			var key := _tile_key(tile)
			if path_set.has(key) or tile == spawn_tile or tile == exit_tile:
				continue
			if rng.randf() < wall_density:
				walls[key] = true

	var tower_nodes: Array[Vector2] = _build_tower_nodes_from_tiles(path_set, walls, rng)
	return {
		"wall_density": wall_density,
		"spawn_tile": spawn_tile,
		"exit_tile": exit_tile,
		"path_tiles": path_tiles,
		"walls": walls,
		"tower_nodes": tower_nodes,
	}

func _pick_edge_tile(rng: RandomNumberGenerator, is_spawn: bool) -> Vector2i:
	if is_spawn:
		if rng.randf() < 0.5:
			return Vector2i(0, int(rng.randi_range(0, BOARD_SIZE - 1)))
		return Vector2i(int(rng.randi_range(0, BOARD_SIZE - 1)), 0)
	if rng.randf() < 0.5:
		return Vector2i(BOARD_SIZE - 1, int(rng.randi_range(0, BOARD_SIZE - 1)))
	return Vector2i(int(rng.randi_range(0, BOARD_SIZE - 1)), BOARD_SIZE - 1)

func _carve_seed_path(spawn_tile: Vector2i, exit_tile: Vector2i, rng: RandomNumberGenerator) -> Array[Vector2i]:
	var path: Array[Vector2i] = [spawn_tile]
	var current := spawn_tile
	while current != exit_tile:
		var options: Array[Vector2i] = []
		if current.x != exit_tile.x:
			var step_x := 1 if exit_tile.x > current.x else -1
			options.append(Vector2i(current.x + step_x, current.y))
		if current.y != exit_tile.y:
			var step_y := 1 if exit_tile.y > current.y else -1
			options.append(Vector2i(current.x, current.y + step_y))
		if rng.randf() < 0.25:
			var lateral: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
			lateral.shuffle()
			for move in lateral:
				var candidate: Vector2i = current + move
				if candidate.x >= 0 and candidate.x < BOARD_SIZE and candidate.y >= 0 and candidate.y < BOARD_SIZE:
					options.append(candidate)
					break
		if options.is_empty():
			break
		current = options[int(rng.randi_range(0, options.size() - 1))]
		if not path.has(current):
			path.append(current)
	if path[path.size() - 1] != exit_tile:
		path.append(exit_tile)
	return path

func _build_tower_nodes_from_tiles(path_set: Dictionary, walls: Dictionary, rng: RandomNumberGenerator) -> Array[Vector2]:
	var nodes: Array[Vector2] = []
	for y in range(1, BOARD_SIZE - 2):
		for x in range(1, BOARD_SIZE - 2):
			var top_left := Vector2i(x, y)
			if not _can_place_tower_tile(top_left, path_set, walls):
				continue
			var center := Vector2(float(x) + 1.0, float(y) + 1.0)
			var too_close := false
			for existing in nodes:
				if existing.distance_to(center) < 3.0:
					too_close = true
					break
			if too_close:
				continue
			if rng.randf() < 0.08:
				nodes.append(center)
	return nodes

func _can_place_tower_tile(tile: Vector2i, path_set: Dictionary, walls: Dictionary) -> bool:
	for oy in range(2):
		for ox in range(2):
			var check := Vector2i(tile.x + ox, tile.y + oy)
			var key := _tile_key(check)
			if walls.has(key) or path_set.has(key):
				return false
	return true

func _tile_key(tile: Vector2i) -> String:
	return "%d,%d" % [tile.x, tile.y]

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
