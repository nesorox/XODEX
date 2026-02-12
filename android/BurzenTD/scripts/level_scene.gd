extends Node2D

const MAX_TOWERS := 9
const LONG_PRESS_SECONDS := 0.4
const TWO_FINGER_WINDOW := 0.18
const PATH_SAFE_DISTANCE := 72.0
const MAX_ACTIVE_CREEPS := 120

@onready var status_label: Label = %StatusLabel
@onready var level_label: Label = %LevelLabel
@onready var wave_label: Label = %WaveLabel
@onready var lives_label: Label = %LivesLabel
@onready var score_label: Label = %ScoreLabel
@onready var action_button: Button = %ActionButton
@onready var menu_button: Button = %MenuButton

var towers: Array = []
var enemies: Array = []
var touch_down_time := {}
var active_touch_count := 0
var two_finger_timer := -1.0

var game_state := "running"
var path_points := PackedVector2Array()
var path_lengths: Array[float] = []
var total_path_length := 0.0
var tower_nodes: Array[Vector2] = []

var wave_index := 1
var wave_count := 3
var wave_creep_count := 120
var wave_spawn_batch := 3
var wave_spawn_interval := 0.14
var wave_spawn_timer := 0.1
var wave_creeps_spawned := 0
var base_hp := 20.0
var hp_step := 1.8
var speed_step := 4.0

var lives := 20
var score := 0
var run_time := 0.0
var global_heat := 0.0
var energy := 140.0
var energy_tick := 11.0
var energy_cap := 240.0

var overlay_mode := 0
var overlay_name := ["NORMAL", "THERMAL", "VECTOR", "WASMUTABLE"]

var map_mutation := {}
var wasmutable_rules := WasmutableRules.new()
var rng := RandomNumberGenerator.new()
var active_event := {}

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
	_update_wave_event(delta)
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
	wave_index = 1

	var wave_def := config.get("wave_definition", {})
	wave_creep_count = wave_def.get("creep_count", 120)
	wave_spawn_batch = wave_def.get("spawn_batch", 3)
	wave_spawn_interval = wave_def.get("spawn_interval", 0.14)
	wave_spawn_timer = 0.15
	base_hp = wave_def.get("base_hp", 20.0)
	hp_step = wave_def.get("hp_step", 1.8)
	speed_step = wave_def.get("speed_step", 4.0)

	tower_nodes = config.get("tower_nodes", [])
	map_mutation = wasmutable_rules.configure_map_mutation(config.get("map_mutation", {}))
	rng.seed = int(config.get("seed", 1)) + int(config.get("level_index", 0)) * 37

	wave_creeps_spawned = 0
	enemies.clear()
	lives = 20
	score = 0
	run_time = 0.0
	global_heat = 0.0
	energy = 140.0
	active_event = wasmutable_rules.update_event(0.0)
	action_button.visible = false
	game_state = "running"

	_build_path_cache()
	var level_index := config.get("level_index", 0)
	var max_level_index := config.get("max_level_index", 1000)
	var seed_name := config.get("seed_label", "AUTO")
	var density_percent := int(round(config.get("layout_profile", {}).get("wall_density", 0.3) * 100.0))
	level_label.text = "L%03d/%03d | Seed %s | %s" % [level_index, max_level_index, seed_name, map_mutation.get("map_name", "BaselineInvariant")]
	status_label.text = "Core v0.00.3.01 active. Grid density %d%%. Tap nodes to place towers." % density_percent

func _build_path_cache() -> void:
	path_lengths.clear()
	total_path_length = 0.0
	for i in range(path_points.size() - 1):
		var segment_length := path_points[i].distance_to(path_points[i + 1])
		path_lengths.append(segment_length)
		total_path_length += segment_length

func _update_wave_event(delta: float) -> void:
	var progress := float(wave_creeps_spawned) / max(1.0, float(wave_creep_count))
	active_event = wasmutable_rules.sample_wave_event(rng, progress)
	active_event = wasmutable_rules.update_event(delta)
	energy += energy_tick * delta * active_event.get("energy_tick_multiplier", 1.0)
	energy = clamp(energy, 0.0, energy_cap)

func _handle_spawning(delta: float) -> void:
	if wave_index > wave_count:
		return
	if enemies.size() >= MAX_ACTIVE_CREEPS:
		return
	wave_spawn_timer -= delta
	if wave_spawn_timer > 0.0:
		return

	if wave_creeps_spawned < wave_creep_count:
		var batch := min(wave_spawn_batch, wave_creep_count - wave_creeps_spawned)
		for i in range(batch):
			_spawn_enemy()
		wave_creeps_spawned += batch
		wave_spawn_timer = wave_spawn_interval
	elif enemies.is_empty():
		LevelManager.record_wave_clear()
		wave_index += 1
		wave_creeps_spawned = 0
		wave_spawn_timer = 1.0
		wave_creep_count = clamp(int(round(wave_creep_count * 1.12)), 100, 500)

func _spawn_enemy() -> void:
	var kind_roll := rng.randf()
	var creep_type := "runner"
	if kind_roll > 0.72:
		creep_type = "tank"
	elif kind_roll > 0.45:
		creep_type = "swarm"

	var hp := base_hp + hp_step * float(wave_index - 1)
	var speed := 70.0 + speed_step * float(wave_index)
	if creep_type == "tank":
		hp *= 2.4
		speed *= 0.72
	elif creep_type == "swarm":
		hp *= 0.6
		speed *= 1.35

	enemies.append({
		"progress": 0.0,
		"hp": hp,
		"max_hp": hp,
		"speed": speed,
		"type": creep_type,
		"pos": path_points[0],
		"flow": Vector2.RIGHT,
	})

func _update_enemies(delta: float) -> void:
	var reached_end := 0
	for enemy in enemies:
		var pressure_speed := wasmutable_rules.compute_enemy_pressure_speed(enemy["speed"], float(score) / max(1.0, run_time), global_heat)
		enemy["progress"] += pressure_speed * delta
		var path_pos := _point_along_path(enemy["progress"])
		var avoid := Vector2.ZERO
		for tower in towers:
			var distance := path_pos.distance_to(tower["pos"])
			if distance < 110.0:
				avoid += (path_pos - tower["pos"]).normalized() * (1.0 - distance / 110.0) * 28.0
		enemy["pos"] = path_pos + avoid
		enemy["flow"] = (enemy["pos"] - path_pos).normalized()

	if enemies.any(func(e): return e["progress"] >= total_path_length):
		for e in enemies:
			if e["progress"] >= total_path_length:
				reached_end += 1
		enemies = enemies.filter(func(e): return e["progress"] < total_path_length and e["hp"] > 0.0)
	else:
		enemies = enemies.filter(func(e): return e["hp"] > 0.0)

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
		if energy < 0.5:
			continue

		var target := _tower_pick_target(t)
		if target == null:
			continue

		var dist_factor := clamp(1.0 - (t["pos"].distance_to(target["pos"]) / t["radius"]), 0.2, 1.0)
		var heat_factor := clamp(1.0 - thermal["heat"] / max(1.0, thermal["capacity"]), 0.25, 1.0)
		var damage := t["base_damage"] * t["role_multiplier"] * t["upgrade_scale"] * dist_factor * heat_factor
		damage *= active_event.get("tower_damage_multiplier", 1.0)

		var aoe_radius := 42.0 + (1.0 - dist_factor) * 54.0
		for enemy in enemies:
			if enemy["pos"].distance_to(target["pos"]) <= aoe_radius:
				enemy["hp"] -= damage
				if enemy["hp"] <= 0.0:
					score += 2

		energy = max(0.0, energy - 1.3)
		thermal["heat"] += thermal["heat_per_shot"] * active_event.get("tower_heat_multiplier", 1.0)
		if thermal["heat"] >= thermal["capacity"]:
			thermal["overheated"] = true

func _tower_pick_target(tower: Dictionary):
	var selected = null
	var selected_hp := INF
	for e in enemies:
		if e["pos"].distance_to(tower["pos"]) <= tower["radius"]:
			if e["hp"] < selected_hp:
				selected = e
				selected_hp = e["hp"]
	return selected

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
			_cycle_overlay()
		else:
			_place_tower(event.position)

func _cycle_overlay() -> void:
	overlay_mode = (overlay_mode + 1) % overlay_name.size()
	status_label.text = "Overlay %s | Event: %s" % [overlay_name[overlay_mode], active_event.get("name", "None")]

func _place_tower(pos: Vector2) -> void:
	if towers.size() >= MAX_TOWERS:
		return
	for t in towers:
		if t["pos"].distance_to(pos) < 80.0:
			return
	if _distance_to_path(pos) < PATH_SAFE_DISTANCE:
		status_label.text = "Too close to corridor flow."
		return
	if not tower_nodes.is_empty():
		var closest := tower_nodes[0]
		for node in tower_nodes:
			if pos.distance_to(node) < pos.distance_to(closest):
				closest = node
		if pos.distance_to(closest) > 56.0:
			status_label.text = "Place towers on active node anchors."
			return
		pos = closest

	var thermal := wasmutable_rules.build_tower_thermal_profile()
	thermal["heat"] = 0.0
	thermal["overheated"] = false
	towers.append({
		"pos": pos,
		"radius": 180.0,
		"base_damage": 5.5,
		"role_multiplier": 1.0 + towers.size() * 0.05,
		"upgrade_scale": 1.0 + float(LevelManager.progress.get("tower_upgrade_points", 0)) * 0.04,
		"thermal": thermal,
	})

func _distance_to_path(pos: Vector2) -> float:
	var closest := INF
	for i in range(path_points.size() - 1):
		var a := path_points[i]
		var b := path_points[i + 1]
		var projected := Geometry2D.get_closest_point_to_segment(pos, a, b)
		closest = min(closest, pos.distance_to(projected))
	return closest

func _check_win_condition() -> void:
	if wave_index > wave_count and enemies.is_empty() and game_state == "running":
		game_state = "won"
		status_label.text = "Run cleared. Progress persisted for single-player shell."
		action_button.text = "Next Level"
		action_button.visible = true

func _set_loss_state() -> void:
	game_state = "lost"
	status_label.text = "Critical exit breached."
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
	wave_label.text = "Wave %d/%d | Creeps %d/%d" % [min(wave_index, wave_count), wave_count, wave_creeps_spawned, wave_creep_count]
	lives_label.text = "Lives %d | Energy %.0f" % [max(lives, 0), energy]
	var event_name := active_event.get("name", "None")
	score_label.text = "Score %d | Heat %.0f%% | %s" % [score, global_heat * 100.0, event_name]

func _draw() -> void:
	var bg := Color("111827")
	if overlay_mode == 3:
		bg = Color("1f2937")
	draw_rect(Rect2(Vector2.ZERO, Vector2(720, 1280)), bg, true)

	if path_points.size() >= 2:
		draw_polyline(path_points, Color("f59e0b"), 34.0, true)
		draw_polyline(path_points, Color("fde68a"), 8.0, true)

	for node in tower_nodes:
		draw_circle(node, 10.0, Color(0.7, 0.75, 1.0, 0.35))

	for e in enemies:
		var p: Vector2 = e["pos"]
		var enemy_color := Color("f8fafc")
		if e["type"] == "tank":
			enemy_color = Color("f97316")
		elif e["type"] == "swarm":
			enemy_color = Color("22d3ee")
		draw_polygon([
			p + Vector2(0, -14),
			p + Vector2(13, 11),
			p + Vector2(-13, 11),
		], [enemy_color])
		var hp_ratio := clamp(float(e["hp"]) / max(1.0, float(e["max_hp"])), 0.0, 1.0)
		draw_rect(Rect2(p + Vector2(-12, -20), Vector2(24 * hp_ratio, 3)), Color(0.2, 1.0, 0.35, 0.8), true)
		if overlay_mode == 2:
			draw_line(p, p + e["flow"] * 18.0, Color(0.5, 0.9, 1.0, 0.7), 2.0)

	for t in towers:
		var thermal = t["thermal"]
		var heat_ratio: float = clamp(thermal["heat"] / thermal["capacity"], 0.0, 1.0)
		var c := Color(0.2 + heat_ratio * 0.8, 0.45 + (1.0 - heat_ratio) * 0.4, 1.0 - heat_ratio, 1.0)
		if thermal["overheated"]:
			c = Color(1.0, 0.2, 0.1, 1.0)
		if overlay_mode == 1:
			c = Color(heat_ratio, 0.2 + (1.0 - heat_ratio) * 0.8, 0.15, 1.0)
		draw_circle(t["pos"], 28.0, c)
		draw_arc(t["pos"], t["radius"], 0.0, TAU, 48, Color(0.5, 0.5, 0.6, 0.2), 2.0)
