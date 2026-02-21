extends Control

const GRID_SIZE := 48.0
const PATH_SAFE_DISTANCE := 72.0

@onready var tower_menu: Tree = %TowerMenu
@onready var tower_detail_label: Label = %TowerDetailLabel
@onready var mob_overlay_label: Label = %MobOverlayLabel
@onready var safety_state_label: Label = %SafetyStateLabel
@onready var placement_hint_label: Label = %PlacementHintLabel
@onready var settings_popup: PopupPanel = %SettingsPopup
@onready var snap_to_grid_check: CheckBox = %SnapToGridCheck

var selected_tower_id := ""
var snap_to_grid := true
var placed_towers: Array[Dictionary] = []
var path_points := PackedVector2Array([
	Vector2(90, 220),
	Vector2(460, 220),
	Vector2(460, 520),
	Vector2(860, 520),
	Vector2(860, 790),
	Vector2(1200, 790),
])

var tower_catalog := {
	"geometric": [
		{"id": "triangle", "label": "△ Triangle", "dps": 42, "range": 150, "cooldown": 1.2, "special": "Burst damage vs clustered mobs."},
		{"id": "square", "label": "▢ Square", "dps": 28, "range": 180, "cooldown": 0.8, "special": "Balanced fire; can apply slow."},
		{"id": "rectangle", "label": "▭ Rectangle", "dps": 24, "range": 260, "cooldown": 1.0, "special": "Long corridor pressure tower."},
	],
	"elemental": [
		{"id": "fire", "label": "火 Fire", "dps": 34, "range": 170, "cooldown": 0.9, "special": "Burn DoT and 1.5x AoE splash."},
		{"id": "water", "label": "水 Water", "dps": 21, "range": 200, "cooldown": 0.7, "special": "Slow aura and single-target control."},
		{"id": "earth", "label": "土 Earth", "dps": 26, "range": 165, "cooldown": 1.1, "special": "Armor break + adjacency durability."},
		{"id": "air", "label": "风 Air", "dps": 25, "range": 220, "cooldown": 0.6, "special": "Fast projectile + knockback."},
	],
	"keystone": [
		{"id": "zhe", "label": "Ж Keystone", "dps": 18, "range": 210, "cooldown": 1.8, "special": "Buff aura + periodic adjacent shield."},
	],
}

func _ready() -> void:
	tower_menu.columns = 2
	tower_menu.set_column_title(0, "Tower")
	tower_menu.set_column_title(1, "DPS")
	tower_menu.column_titles_visible = true
	_rebuild_tower_menu()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _is_world_placement_position(event.position):
			_try_place_tower(event.position)

func _is_world_placement_position(position: Vector2) -> bool:
	return position.y > 96.0 and position.y < size.y - 160.0 and position.x < size.x - 392.0

func _rebuild_tower_menu() -> void:
	tower_menu.clear()
	var root := tower_menu.create_item()
	_add_tower_group(root, "Geometric", tower_catalog["geometric"])
	_add_tower_group(root, "Elemental", tower_catalog["elemental"])
	_add_tower_group(root, "Keystone", tower_catalog["keystone"])

func _add_tower_group(root: TreeItem, title: String, entries: Array) -> void:
	var group := tower_menu.create_item(root)
	group.set_text(0, title)
	group.collapsed = false
	for entry in entries:
		var item := tower_menu.create_item(group)
		item.set_text(0, entry["label"])
		item.set_text(1, str(entry["dps"]))
		item.set_metadata(0, entry)

func _on_tower_menu_item_selected() -> void:
	var item := tower_menu.get_selected()
	if item == null:
		return
	var meta = item.get_metadata(0)
	if meta == null:
		return
	selected_tower_id = str(meta["id"])
	tower_detail_label.text = "[%s]\nDPS %d | Range %d | CD %.2fs\n%s" % [
		meta["label"],
		meta["dps"],
		meta["range"],
		meta["cooldown"],
		meta["special"],
	]
	placement_hint_label.text = "Selected %s. Click in world to place." % meta["label"]

func _try_place_tower(raw_position: Vector2) -> void:
	if selected_tower_id.is_empty():
		safety_state_label.text = "NESOROX Safety: Waiting for tower selection"
		return
	var target := raw_position
	if snap_to_grid:
		target = Vector2(round(target.x / GRID_SIZE) * GRID_SIZE, round(target.y / GRID_SIZE) * GRID_SIZE)
	for tower in placed_towers:
		if tower["pos"].distance_to(target) < 56.0:
			safety_state_label.text = "NESOROX Safety: overlap violation; placement reverted"
			return
	if _distance_to_path(target) < PATH_SAFE_DISTANCE:
		safety_state_label.text = "NESOROX Safety: pathing violation; placement reverted"
		return
	placed_towers.append({"id": selected_tower_id, "pos": target})
	safety_state_label.text = "NESOROX Safety: Stable"
	mob_overlay_label.text = "Mob Overlay: HP %d | Armor %d | Speed %.2f" % [120 + placed_towers.size() * 5, 14 + placed_towers.size(), 1.0 + placed_towers.size() * 0.03]
	queue_redraw()

func _distance_to_path(pos: Vector2) -> float:
	var closest := INF
	for i in range(path_points.size() - 1):
		var projected := Geometry2D.get_closest_point_to_segment(pos, path_points[i], path_points[i + 1])
		closest = min(closest, pos.distance_to(projected))
	return closest

func _on_settings_button_pressed() -> void:
	settings_popup.popup_centered()

func _on_snap_toggled(button_pressed: bool) -> void:
	snap_to_grid = button_pressed

func _on_simulate_wave_pressed() -> void:
	mob_overlay_label.text = "Mob Overlay: Wave sim => tanks 4, runners 9, affinity 2"

func _on_clear_placements_pressed() -> void:
	placed_towers.clear()
	safety_state_label.text = "NESOROX Safety: Stable (baseline restored)"
	queue_redraw()

func _draw() -> void:
	if path_points.size() > 1:
		draw_polyline(path_points, Color("f59e0b"), 26.0, true)
		draw_polyline(path_points, Color("fde68a"), 7.0, true)
	for tower in placed_towers:
		var pos: Vector2 = tower["pos"]
		draw_circle(pos, 16.0, Color("93c5fd"))
		draw_arc(pos, 140.0, 0.0, TAU, 40, Color(0.6, 0.8, 1.0, 0.25), 2.0)
