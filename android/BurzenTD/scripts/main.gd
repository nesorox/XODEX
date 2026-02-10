extends Node2D

const MAX_TOWERS := 5
const ENEMY_SPEED := 120.0
const ENEMY_SPAWN_INTERVAL := 1.4
const LONG_PRESS_SECONDS := 0.4
const TWO_FINGER_WINDOW := 0.18
const BASELINE_Y := 640.0
const GOAL_X := 740.0

const COLOR_BG := Color("111827")
const COLOR_ENEMY := Color("f8fafc")

const THERMAL_DEFAULT := {
	"capacity": 100.0,
	"heat_per_shot": 18.0,
	"dissipation_rate": 14.0,
	"recovery_ratio": 0.45,
}

const WASMUTABLE_CYCLE_SECONDS := 20.0
const WASMUTABLE_SHIFT_FACTOR := 1.08

var towers: Array = []
var enemies: Array = []
var spawn_timer := 0.0
var cycle_timer := WASMUTABLE_CYCLE_SECONDS
var lost := false
var touch_down_time := {}
var active_touch_count := 0
var two_finger_timer := -1.0
var wasm_rules := WasmutableRules.new()

func _ready() -> void:
	randomize()
	set_process(true)
	_restart_run()

func _process(delta: float) -> void:
	if two_finger_timer >= 0.0:
		two_finger_timer -= delta

	if lost:
		queue_redraw()
		return

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_enemy()
		spawn_timer = ENEMY_SPAWN_INTERVAL

	cycle_timer -= delta
	if cycle_timer <= 0.0:
		_apply_wasmutable_cycle()
		cycle_timer = WASMUTABLE_CYCLE_SECONDS

	_update_enemies(delta)
	_update_towers(delta)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		active_touch_count += 1
		touch_down_time[event.index] = Time.get_ticks_msec() / 1000.0
		if active_touch_count >= 2:
			two_finger_timer = TWO_FINGER_WINDOW
		return

	active_touch_count = max(0, active_touch_count - 1)
	var now := Time.get_ticks_msec() / 1000.0
	var start = touch_down_time.get(event.index, now)
	var hold_time := now - start
	touch_down_time.erase(event.index)

	if two_finger_timer >= 0.0:
		_restart_run()
		return

	if hold_time >= LONG_PRESS_SECONDS:
		_highlight_tower(event.position)
		return

	if lost:
		_restart_run()
	else:
		_place_tower(event.position)

func _spawn_enemy() -> void:
	enemies.append({
		"pos": Vector2(-20.0, BASELINE_Y + randf_range(-120.0, 120.0)),
		"hp": 1,
	})

func _update_enemies(delta: float) -> void:
	for enemy in enemies:
		enemy["pos"].x += ENEMY_SPEED * delta
		enemy["pos"].y += _flow_bias(enemy["pos"], delta)

	if enemies.any(func(e): return e["pos"].x >= GOAL_X):
		lost = true
		enemies.clear()

func _flow_bias(pos: Vector2, delta: float) -> float:
	var bias := (BASELINE_Y - pos.y) * 0.25 * delta
	for t in towers:
		var d := pos.distance_to(t["pos"])
		if d < t["radius"]:
			# Towers create repulsive pressure that bends trajectories.
			var away := (pos.y - t["pos"].y)
			bias += clamp(away / max(1.0, d), -1.0, 1.0) * 95.0 * delta
	return bias

func _update_towers(delta: float) -> void:
	for t in towers:
		var thermal: Dictionary = t["thermal"]
		thermal["heat"] = max(0.0, thermal["heat"] - thermal["dissipation_rate"] * delta)
		if thermal["overheated"] and thermal["heat"] <= thermal["capacity"] * thermal["recovery_ratio"]:
			thermal["overheated"] = false

		if thermal["overheated"]:
			continue

		var target_idx := _find_target_idx(t)
		if target_idx >= 0:
			thermal["heat"] += thermal["heat_per_shot"]
			enemies[target_idx]["hp"] -= 1
			if enemies[target_idx]["hp"] <= 0:
				enemies.remove_at(target_idx)
			if thermal["heat"] >= thermal["capacity"]:
				thermal["overheated"] = true

		if t["highlight"] > 0.0:
			t["highlight"] = max(0.0, t["highlight"] - delta * 2.2)

func _find_target_idx(tower: Dictionary) -> int:
	for i in range(enemies.size()):
		if enemies[i]["pos"].distance_to(tower["pos"]) <= tower["radius"]:
			return i
	return -1

func _place_tower(pos: Vector2) -> void:
	if towers.size() >= MAX_TOWERS:
		return

	for t in towers:
		if t["pos"].distance_to(pos) < 80.0:
			return

	var thermal := wasm_rules.thermal_profile.duplicate(true)
	thermal["heat"] = 0.0
	thermal["overheated"] = false
	towers.append({
		"pos": pos,
		"radius": 180.0,
		"thermal": thermal,
		"highlight": 0.0,
	})

func _highlight_tower(pos: Vector2) -> void:
	for t in towers:
		if t["pos"].distance_to(pos) <= 42.0:
			t["highlight"] = 1.0

func _restart_run() -> void:
	towers.clear()
	enemies.clear()
	lost = false
	spawn_timer = 0.2
	cycle_timer = WASMUTABLE_CYCLE_SECONDS
	two_finger_timer = -1.0
	wasm_rules.reset_to_defaults(THERMAL_DEFAULT)

func _apply_wasmutable_cycle() -> void:
	# Continuous refinement hook: rules become slightly harsher each cycle.
	var profile := wasm_rules.mutate_for_pressure_cycle(WASMUTABLE_SHIFT_FACTOR)
	for t in towers:
		var thermal: Dictionary = t["thermal"]
		thermal["capacity"] = profile["capacity"]
		thermal["heat_per_shot"] = profile["heat_per_shot"]
		thermal["dissipation_rate"] = profile["dissipation_rate"]
		thermal["recovery_ratio"] = profile["recovery_ratio"]

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(720, 1280)), COLOR_BG, true)

	for e in enemies:
		var p: Vector2 = e["pos"]
		draw_polygon([
			p + Vector2(0, -14),
			p + Vector2(13, 11),
			p + Vector2(-13, 11),
		], [COLOR_ENEMY])

	for t in towers:
		var thermal: Dictionary = t["thermal"]
		var heat_ratio: float = clamp(thermal["heat"] / thermal["capacity"], 0.0, 1.0)
		var c := Color(0.2 + heat_ratio * 0.8, 0.45 + (1.0 - heat_ratio) * 0.4, 1.0 - heat_ratio, 1.0)
		if thermal["overheated"]:
			c = Color(1.0, 0.2, 0.1, 1.0)

		draw_circle(t["pos"], 28.0, c)
		draw_arc(t["pos"], t["radius"], 0.0, TAU, 48, Color(0.5, 0.5, 0.6, 0.2), 2.0)

		if t["highlight"] > 0.0:
			draw_circle(t["pos"], 38.0, Color(1, 1, 1, 0.2 * t["highlight"]))

	if lost:
		draw_rect(Rect2(Vector2.ZERO, Vector2(720, 1280)), Color(0, 0, 0, 0.5), true)
