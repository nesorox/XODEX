extends Node2D

const MAX_TOWERS := 7
const ENEMY_SPAWN_INTERVAL := 0.8
const LONG_PRESS_SECONDS := 0.4
const TWO_FINGER_WINDOW := 0.18
const PATH_SAFE_DISTANCE := 72.0

@onready var status_label: Label = %StatusLabel
@onready var level_label: Label = %LevelLabel
@onready var wave_label: Label = %WaveLabel
@onready var lives_label: Label = %LivesLabel
@onready var score_label: Label = %ScoreLabel
@onready var action_button: Button = %ActionButton
@onready var menu_button: Button = %MenuButton

var towers: Array = []
var enemies: Array = []
var spawn_timer := 0.0
var touch_down_time := {}
var active_touch_count := 0
var two_finger_timer := -1.0

var game_state := "running"
var path_points := PackedVector2Array()
var path_lengths: Array[float] = []
var total_path_length := 0.0

var wave_index := 1
var wave_count := 3
var enemies_per_wave := 6
var enemies_spawned_in_wave := 0
var enemy_speed := 120.0
var base_enemy_speed := 120.0
var lives := 3
var score := 0
var run_time := 0.0
var global_heat := 0.0

var map_mutation := {}
var wasmutable_rules := WasmutableRules.new()

func _ready() -> void:
	set_process(true)
	_load_level()
	_update_hud()

func _process(delta: float) -> void:
	if two_finger_timer >= 0.0:
		two_finger_timer -= delta
		if two_finger_timer < 0.0:
			two_finger_timer = -1.0

	if game_state != "running":
		queue_redraw()
		return

	run_time += delta
	_handle_spawning(delta)
	_update_enemies(delta)
	_update_towers(delta)
	_update_mutation_state(delta)
	_check_win_condition()
	_update_hud()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)

func _load_level() -> void:
	var config: Dictionary = LevelManager.get_level_config()
	path_points = config.get("path_points", PackedVector2Array([Vector2(40, 640), Vector2(680, 640)]))
	wave_count = config.get("wave_count", 3)
	enemies_per_wave = config.get("enemies_per_wave", 6)
	base_enemy_speed = config.get("enemy_speed", 120.0)
	enemy_speed = base_enemy_speed
	map_mutation = wasmutable_rules.configure_map_mutation(config.get("map_mutation", {}))
	wave_index = 1
	enemies_spawned_in_wave = 0
	spawn_timer = 0.25
	game_state = "running"
	lives = 3
	score = 0
	run_time = 0.0
	global_heat = 0.0
	action_button.visible = false
	_build_path_cache()
	var level_index := config.get("level_index", 0)
	var max_level_index := config.get("max_level_index", 1000)
	var seed_name := config.get("seed_label", "AUTO")
	var layout_profile := config.get("layout_profile", {})
	var density_percent := int(round(layout_profile.get("wall_density", 0.3) * 100.0))
	level_label.text = "Level %03d/%03d | Seed %s | %s" % [level_index, max_level_index, seed_name, map_mutation.get("map_name", "BaselineInvariant")]
	status_label.text = "Seeded grid density %d%%. Tap to place towers. Hold on tower to pulse heat ring." % density_percent

func _build_path_cache() -> void:
	path_lengths.clear()
	total_path_length = 0.0
	for i in range(path_points.size() - 1):
		var segment_length := path_points[i].distance_to(path_points[i + 1])
		path_lengths.append(segment_length)
		total_path_length += segment_length

func _handle_spawning(delta: float) -> void:
	if wave_index > wave_count:
		return
	spawn_timer -= delta
	if spawn_timer > 0.0:
		return

	if enemies_spawned_in_wave < enemies_per_wave:
		_spawn_enemy()
		enemies_spawned_in_wave += 1
		spawn_timer = ENEMY_SPAWN_INTERVAL
	elif enemies.is_empty():
		wave_index += 1
		enemies_spawned_in_wave = 0
		spawn_timer = 1.0

func _spawn_enemy() -> void:
	enemies.append({
		"progress": 0.0,
		"pos": path_points[0],
	})

func _update_enemies(delta: float) -> void:
	var reached_end := 0
	for enemy in enemies:
		enemy["progress"] += enemy_speed * delta
		enemy["pos"] = _point_along_path(enemy["progress"])
	if enemies.any(func(e): return e["progress"] >= total_path_length):
		for e in enemies:
			if e["progress"] >= total_path_length:
				reached_end += 1
		enemies = enemies.filter(func(e): return e["progress"] < total_path_length)

	if reached_end > 0:
		lives -= reached_end
		if lives <= 0:
			_set_loss_state()

func _point_along_path(progress: float) -> Vector2:
	if path_points.size() < 2:
		return Vector2(40, 640)
	var clamped_progress := clamp(progress, 0.0, total_path_length)
	var cursor := 0.0
	for i in range(path_lengths.size()):
		var segment := path_lengths[i]
		if clamped_progress <= cursor + segment:
			var t := (clamped_progress - cursor) / max(segment, 0.001)
			return path_points[i].lerp(path_points[i + 1], t)
		cursor += segment
	return path_points[path_points.size() - 1]

func _update_towers(delta: float) -> void:
	for t in towers:
		var thermal = t["thermal"]
		thermal["heat"] = max(0.0, thermal["heat"] - thermal["dissipation_rate"] * delta)
		if thermal["overheated"] and thermal["heat"] <= thermal["capacity"] * thermal["recovery_ratio"]:
			thermal["overheated"] = false

		if thermal["overheated"]:
			continue

		if _tower_has_target(t):
			thermal["heat"] += thermal["heat_per_shot"]
			score += 1
			if thermal["heat"] >= thermal["capacity"]:
				thermal["overheated"] = true

func _update_mutation_state(delta: float) -> void:
	var combined_heat := 0.0
	for t in towers:
		var thermal = t["thermal"]
		combined_heat += clamp(thermal["heat"] / max(1.0, thermal["capacity"]), 0.0, 1.0)
	var target_heat := 0.0
	if towers.size() > 0:
		target_heat = combined_heat / towers.size()
	var decay := clamp(map_mutation.get("heat_decay_coefficient", 0.2) * delta * 4.0, 0.01, 1.0)
	global_heat = lerpf(global_heat, target_heat, decay)

	var efficiency := float(score) / max(1.0, run_time)
	enemy_speed = wasmutable_rules.compute_enemy_pressure_speed(base_enemy_speed, efficiency, global_heat)

func _tower_has_target(tower: Dictionary) -> bool:
	for e in enemies:
		if e["pos"].distance_to(tower["pos"]) <= tower["radius"]:
			return true
	return false

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		active_touch_count += 1
		touch_down_time[event.index] = Time.get_ticks_msec() / 1000.0
		if active_touch_count >= 2:
			two_finger_timer = TWO_FINGER_WINDOW
	else:
		active_touch_count = max(0, active_touch_count - 1)
		var now := Time.get_ticks_msec() / 1000.0
		var start = touch_down_time.get(event.index, now)
		var hold_time := now - start
		touch_down_time.erase(event.index)

		if two_finger_timer >= 0.0:
			_restart_level()
			return

		if game_state != "running":
			return

		if hold_time >= LONG_PRESS_SECONDS:
			_highlight_tower(event.position)
		else:
			_place_tower(event.position)

func _place_tower(pos: Vector2) -> void:
	if towers.size() >= MAX_TOWERS:
		return
	for t in towers:
		if t["pos"].distance_to(pos) < 80.0:
			return
	if _distance_to_path(pos) < PATH_SAFE_DISTANCE:
		status_label.text = "Too close to path. Place tower on open lane."
		return

	var thermal := wasmutable_rules.build_tower_thermal_profile()
	thermal["heat"] = 0.0
	thermal["overheated"] = false
	towers.append({
		"pos": pos,
		"radius": 180.0,
		"thermal": thermal,
		"highlight": 0.0,
	})

func _distance_to_path(pos: Vector2) -> float:
	var closest := INF
	for i in range(path_points.size() - 1):
		var a := path_points[i]
		var b := path_points[i + 1]
		var projected := Geometry2D.get_closest_point_to_segment(pos, a, b)
		closest = min(closest, pos.distance_to(projected))
	return closest

func _highlight_tower(pos: Vector2) -> void:
	for t in towers:
		if t["pos"].distance_to(pos) <= 42.0:
			t["highlight"] = 1.0

func _check_win_condition() -> void:
	if wave_index > wave_count and enemies.is_empty() and game_state == "running":
		game_state = "won"
		status_label.text = "Run cleared. Ready for next procedural route."
		action_button.text = "Next Level"
		action_button.visible = true

func _set_loss_state() -> void:
	game_state = "lost"
	status_label.text = "Breach detected. Cooling down failed."
	action_button.text = "Retry"
	action_button.visible = true
	enemies.clear()

func _restart_level() -> void:
	towers.clear()
	enemies.clear()
	touch_down_time.clear()
	active_touch_count = 0
	two_finger_timer = -1.0
	LevelManager.retry_level()

func _on_action_button_pressed() -> void:
	if game_state == "won":
		LevelManager.next_level()
	elif game_state == "lost":
		LevelManager.retry_level()

func _on_menu_button_pressed() -> void:
	LevelManager.return_to_menu()

func _update_hud() -> void:
	wave_label.text = "Wave %d/%d" % [min(wave_index, wave_count), wave_count]
	lives_label.text = "Lives: %d" % max(lives, 0)
	var fog_percent := int(round(map_mutation.get("fog_density", 0.0) * 100.0))
	score_label.text = "Heat Score: %d | Pressure %.0f%% | Fog %d%%" % [score, global_heat * 100.0, fog_percent]

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(720, 1280)), Color("111827"), true)
	if path_points.size() >= 2:
		draw_polyline(path_points, Color("f59e0b"), 34.0, true)
		draw_polyline(path_points, Color("fde68a"), 8.0, true)

	for e in enemies:
		var p: Vector2 = e["pos"]
		draw_polygon([
			p + Vector2(0, -14),
			p + Vector2(13, 11),
			p + Vector2(-13, 11),
		], [Color("f8fafc")])

	for t in towers:
		var thermal = t["thermal"]
		var heat_ratio: float = clamp(thermal["heat"] / thermal["capacity"], 0.0, 1.0)
		var c := Color(0.2 + heat_ratio * 0.8, 0.45 + (1.0 - heat_ratio) * 0.4, 1.0 - heat_ratio, 1.0)
		if thermal["overheated"]:
			c = Color(1.0, 0.2, 0.1, 1.0)
		draw_circle(t["pos"], 28.0, c)
		draw_arc(t["pos"], t["radius"], 0.0, TAU, 48, Color(0.5, 0.5, 0.6, 0.2), 2.0)

		if t["highlight"] > 0.0:
			draw_circle(t["pos"], 38.0, Color(1, 1, 1, 0.2))
			t["highlight"] = max(0.0, t["highlight"] - 0.04)
