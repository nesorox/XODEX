extends Node2D

const MAX_TOWERS := 9
const LONG_PRESS_SECONDS := 0.4
const TWO_FINGER_WINDOW := 0.18
const MAX_ACTIVE_CREEPS := 120
const BOARD_SIZE := 80
const TILE_PIXELS := 8.0
const BOARD_ORIGIN := Vector2(40, 320)

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
var path_tiles: Array[Vector2i] = []
var path_set := {}
var wall_tiles := {}
var spawn_tile := Vector2i.ZERO
var exit_tile := Vector2i(BOARD_SIZE - 1, BOARD_SIZE - 1)
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
	path_tiles = config.get("path_tiles", [])
	path_set.clear()
	for tile in path_tiles:
		path_set[_tile_key(tile)] = true
	wall_tiles = config.get("walls", {})
	spawn_tile = config.get("spawn_tile", Vector2i(0, 0))
	exit_tile = config.get("exit_tile", Vector2i(BOARD_SIZE - 1, BOARD_SIZE - 1))
	wave_count = config.get("wave_count", 3)
	wave_index = 1

	var wave_def: Dictionary = config.get("wave_definition", {})
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

	var level_index: int = int(config.get("level_index", 0))
	var max_level_index: int = int(config.get("max_level_index", 1000))
	var seed_name: String = str(config.get("seed_label", "AUTO"))
	var density_percent: int = int(round(float(config.get("layout_profile", {}).get("wall_density", 0.3)) * 100.0))
	level_label.text = "L%03d/%03d | Seed %s | %s" % [level_index, max_level_index, seed_name, map_mutation.get("map_name", "BaselineInvariant")]
	status_label.text = "Core v0.00.3.02 active. Grid density %d%%. Tap node anchors to place 2x2 towers." % density_percent

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
		"tile_progress": 0.0,
		"hp": hp,
		"max_hp": hp,
		"speed": speed,
		"type": creep_type,
		"tile": spawn_tile,
		"pos": _tile_to_world_center(spawn_tile),
		"flow": Vector2.RIGHT,
	})

func _update_enemies(delta: float) -> void:
	var reached_end := 0
	for enemy in enemies:
		var pressure_speed := wasmutable_rules.compute_enemy_pressure_speed(enemy["speed"], float(score) / max(1.0, run_time), global_heat)
		enemy["tile_progress"] += (pressure_speed / TILE_PIXELS) * delta
		var tile_index := min(int(enemy["tile_progress"]), max(path_tiles.size() - 1, 0))
		enemy["tile"] = path_tiles[tile_index] if not path_tiles.is_empty() else exit_tile
		var next_index := min(tile_index + 1, max(path_tiles.size() - 1, 0))
		var current_world := _tile_to_world_center(enemy["tile"])
		var next_world := _tile_to_world_center(path_tiles[next_index] if not path_tiles.is_empty() else exit_tile)
		enemy["pos"] = current_world
		enemy["flow"] = (next_world - current_world).normalized()

	if enemies.any(func(e): return int(e["tile_progress"]) >= max(path_tiles.size() - 1, 0)):
		for e in enemies:
			if int(e["tile_progress"]) >= max(path_tiles.size() - 1, 0):
				reached_end += 1
		enemies = enemies.filter(func(e): return int(e["tile_progress"]) < max(path_tiles.size() - 1, 0) and e["hp"] > 0.0)
	else:
		enemies = enemies.filter(func(e): return e["hp"] > 0.0)

	if reached_end > 0:
		lives -= reached_end
		if lives <= 0:
			_set_loss_state()

func _tile_to_world_center(tile: Vector2i) -> Vector2:
	return BOARD_ORIGIN + Vector2((tile.x + 0.5) * TILE_PIXELS, (tile.y + 0.5) * TILE_PIXELS)

func _world_to_tile(pos: Vector2) -> Vector2i:
	var local := (pos - BOARD_ORIGIN) / TILE_PIXELS
	return Vector2i(clamp(int(floor(local.x)), 0, BOARD_SIZE - 1), clamp(int(floor(local.y)), 0, BOARD_SIZE - 1))

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
	var selected: Dictionary = {}
	var selected_hp: float = INF
	for e in enemies:
		if e["pos"].distance_to(tower["pos"]) <= tower["radius"]:
			if e["hp"] < selected_hp:
				selected = e
				selected_hp = e["hp"]
	return selected if not selected.is_empty() else null

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
		var now: float = Time.get_ticks_msec() / 1000.0
		var start: float = float(touch_down_time.get(event.index, now))
		var hold_time: float = now - start
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
	if tower_nodes.is_empty():
		return
	var tile_pick: Vector2i = _world_to_tile(pos)
	var tile_pick_vec: Vector2 = Vector2(tile_pick.x, tile_pick.y)
	var closest: Vector2 = tower_nodes[0]
	for node in tower_nodes:
		if tile_pick_vec.distance_to(node) < tile_pick_vec.distance_to(closest):
			closest = node
	if tile_pick_vec.distance_to(closest) > 2.0:
		status_label.text = "Place towers on active node anchors."
		return
	var top_left: Vector2i = Vector2i(int(closest.x - 1.0), int(closest.y - 1.0))
	if not _can_place_tower(top_left):
		status_label.text = "Invalid 2x2 placement or blocked path."
		return

	var thermal: Dictionary = wasmutable_rules.build_tower_thermal_profile()
	thermal["heat"] = 0.0
	thermal["overheated"] = false
	towers.append({
		"tile": top_left,
		"pos": _tile_to_world_center(Vector2i(top_left.x + 1, top_left.y + 1)),
		"radius": 180.0,
		"base_damage": 5.5,
		"role_multiplier": 1.0 + towers.size() * 0.05,
		"upgrade_scale": 1.0 + float(LevelManager.progress.get("tower_upgrade_points", 0)) * 0.04,
		"thermal": thermal,
	})
	_rebuild_path_from_grid()

func _can_place_tower(top_left: Vector2i) -> bool:
	if top_left.x < 0 or top_left.y < 0 or top_left.x > BOARD_SIZE - 2 or top_left.y > BOARD_SIZE - 2:
		return false
	for oy in range(2):
		for ox in range(2):
			var tile := Vector2i(top_left.x + ox, top_left.y + oy)
			var key := _tile_key(tile)
			if wall_tiles.has(key) or tile == spawn_tile or tile == exit_tile:
				return false
	for existing in towers:
		var existing_tile: Vector2i = existing["tile"]
		if abs(existing_tile.x - top_left.x) <= 2 and abs(existing_tile.y - top_left.y) <= 2:
			return false
	return _test_path_with_tower(top_left)

func _test_path_with_tower(top_left: Vector2i) -> bool:
	var blocked: Dictionary = wall_tiles.duplicate(true)
	for t in towers:
		var origin: Vector2i = t["tile"]
		for oy in range(2):
			for ox in range(2):
				blocked[_tile_key(Vector2i(origin.x + ox, origin.y + oy))] = true
	for oy in range(2):
		for ox in range(2):
			blocked[_tile_key(Vector2i(top_left.x + ox, top_left.y + oy))] = true
	return not _find_path(spawn_tile, exit_tile, blocked).is_empty()

func _rebuild_path_from_grid() -> void:
	var blocked: Dictionary = wall_tiles.duplicate(true)
	for t in towers:
		var origin: Vector2i = t["tile"]
		for oy in range(2):
			for ox in range(2):
				blocked[_tile_key(Vector2i(origin.x + ox, origin.y + oy))] = true
	var new_path: Array[Vector2i] = _find_path(spawn_tile, exit_tile, blocked)
	if not new_path.is_empty():
		path_tiles = new_path

func _find_path(start: Vector2i, goal: Vector2i, blocked: Dictionary) -> Array[Vector2i]:
	var frontier: Array[Vector2i] = [start]
	var came_from := {_tile_key(start): start}
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		if current == goal:
			break
		for dir in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var nxt := current + dir
			if nxt.x < 0 or nxt.y < 0 or nxt.x >= BOARD_SIZE or nxt.y >= BOARD_SIZE:
				continue
			var key := _tile_key(nxt)
			if blocked.has(key) or came_from.has(key):
				continue
			came_from[key] = current
			frontier.push_back(nxt)
	if not came_from.has(_tile_key(goal)):
		return []
	var path: Array[Vector2i] = [goal]
	var cursor: Vector2i = goal
	while cursor != start:
		cursor = came_from[_tile_key(cursor)]
		path.push_front(cursor)
	return path

func _tile_key(tile: Vector2i) -> String:
	return "%d,%d" % [tile.x, tile.y]

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
	var event_name: String = str(active_event.get("name", "None"))
	score_label.text = "Score %d | Heat %.0f%% | %s" % [score, global_heat * 100.0, event_name]

func _draw() -> void:
	var bg := Color("111827")
	if overlay_mode == 3:
		bg = Color("1f2937")
	draw_rect(Rect2(Vector2.ZERO, Vector2(720, 1280)), bg, true)

	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			var tile := Vector2i(x, y)
			var p := BOARD_ORIGIN + Vector2(x, y) * TILE_PIXELS
			var color := Color("f3e9d2")
			if wall_tiles.has(_tile_key(tile)):
				color = Color("6b7280")
			draw_rect(Rect2(p, Vector2.ONE * TILE_PIXELS), color, true)

	for tile in path_tiles:
		draw_rect(Rect2(BOARD_ORIGIN + Vector2(tile.x, tile.y) * TILE_PIXELS, Vector2.ONE * TILE_PIXELS), Color(0.95, 0.65, 0.2, 0.4), true)

	for node in tower_nodes:
		draw_circle(_tile_to_world_center(Vector2i(int(node.x), int(node.y))), 3.0, Color(0.2, 0.35, 0.8, 0.6))

	draw_circle(_tile_to_world_center(spawn_tile), 4.0, Color("22c55e"))
	draw_circle(_tile_to_world_center(exit_tile), 4.0, Color("facc15"))

	for e in enemies:
		var p: Vector2 = e["pos"]
		var hp_ratio := clamp(float(e["hp"]) / max(1.0, float(e["max_hp"])), 0.0, 1.0)
		var enemy_color := Color("ef4444")
		if hp_ratio < 0.66:
			enemy_color = Color("f97316")
		if hp_ratio < 0.33:
			enemy_color = Color("facc15")
		var flow: Vector2 = e["flow"]
		if flow.length() < 0.1:
			flow = Vector2.RIGHT
		flow = flow.normalized()
		var left := Vector2(-flow.y, flow.x)
		var tip := p + flow * 4.0
		var back := p - flow * 3.0
		draw_polygon([
			tip,
			back + left * 3.0,
			back - left * 3.0,
		], [enemy_color])
		if overlay_mode == 2:
			draw_line(p, p + flow * 10.0, Color(0.5, 0.9, 1.0, 0.7), 1.0)

	for t in towers:
		var thermal = t["thermal"]
		var heat_ratio: float = clamp(thermal["heat"] / thermal["capacity"], 0.0, 1.0)
		var c := Color(0.2 + heat_ratio * 0.8, 0.45 + (1.0 - heat_ratio) * 0.4, 1.0 - heat_ratio, 1.0)
		if thermal["overheated"]:
			c = Color(1.0, 0.2, 0.1, 1.0)
		if overlay_mode == 1:
			c = Color(heat_ratio, 0.2 + (1.0 - heat_ratio) * 0.8, 0.15, 0.55)
		var origin: Vector2i = t["tile"]
		for oy in range(2):
			for ox in range(2):
				var tile_pos := BOARD_ORIGIN + Vector2(origin.x + ox, origin.y + oy) * TILE_PIXELS
				draw_rect(Rect2(tile_pos, Vector2.ONE * TILE_PIXELS), Color("1e3a8a"), true)
				if overlay_mode == 1:
					draw_rect(Rect2(tile_pos, Vector2.ONE * TILE_PIXELS), c, true)
		draw_circle(t["pos"], 1.6, Color("a855f7"))
