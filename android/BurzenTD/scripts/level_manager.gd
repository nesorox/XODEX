# GODOT 4.6.1 STRICT – SINGLETON ARCHITECTURE FIXED – v0.00.6.1
extends Node

const LEVEL_SCENE: String = "res://scenes/level_scene.tscn"
const CAMPAIGN_ROOT_SCENE: String = "res://scenes/CampaignRoot.tscn"
const MAIN_MENU_SCENE: String = "res://scenes/MainMenu.tscn"
const CAMPAIGN_SELECT_SCENE: String = "res://ui/campaign_select.tscn"
const SETTINGS_FILE: String = "user://burzen_settings.cfg"
const HEAT_CONFIG_PATH: String = "res://settings/heat_config.json"
const DEMO_LEVEL_ORDER: Array[String] = [
	"level_01_first_fold",
	"level_02_thermal_balance",
	"level_03_neighbor_bonds",
	"level_04_tissue_emergence",
	"level_05_pathway_design",
]

const DEFAULT_SETTINGS: Dictionary = {
	"general": {"master_volume": 0.8, "game_speed": 1.0, "hud_enabled": true},
	"tower": {"attack_visualization": true, "range_overlay": true, "keystone_abilities": true},
	"wave": {"spawn_rate_multiplier": 1.0, "difficulty_scale": 1.0},
	"heat": {"difficulty_preset": "normal", "global_heat_multiplier": 1.0, "tower_heat_tolerance_boost": 0.0, "cooling_efficiency": 1.0, "visual_heat_feedback_intensity": 1.0, "educational_heat_tooltips": true},
	"advanced": {"debug_logs": false, "simulation_mode": false},
}

var level_index: int = 0
var current_seed: int = 0
var settings: Dictionary = {}
var campaign_mode: bool = false
var current_level_id: String = ""
var demo_levels: Dictionary = {}
var selected_campaign_version: String = "v0.00.6"

func _ready() -> void:
	if OS.has_feature("pc") or OS.has_feature("web"):
		DisplayServer.window_set_size(Vector2i(1280, 720))
	settings = DEFAULT_SETTINGS.duplicate(true)
	_load_heat_config_into_defaults()
	_load_demo_levels()
	load_settings()
	apply_audio_settings()
	await get_tree().process_frame
	SingletonGuard.assert_singleton_ready("HeatEngine", "LevelManager._ready")
	_apply_heat_runtime_settings()

func start_new_run() -> void:
	campaign_mode = false
	level_index = 1
	current_seed = randi()
	_load_level_scene()

func show_campaign_select() -> void:
	get_tree().change_scene_to_file(CAMPAIGN_SELECT_SCENE)

func set_campaign_version(version_id: String) -> void:
	selected_campaign_version = version_id

func get_campaign_version() -> String:
	return selected_campaign_version

func start_selected_campaign() -> void:
	if selected_campaign_version == "v0.8":
		campaign_mode = true
		current_level_id = "campaign_v0_8"
		get_tree().change_scene_to_file(CAMPAIGN_ROOT_SCENE)
		return
	show_campaign_select()

func start_demo_campaign() -> void:
	campaign_mode = true
	start_demo_level(DEMO_LEVEL_ORDER[0])

func start_demo_level(level_id: String) -> void:
	campaign_mode = true
	current_level_id = level_id
	level_index = max(1, DEMO_LEVEL_ORDER.find(level_id) + 1)
	current_seed = level_index * 1001
	_load_level_scene()

func retry_level() -> void:
	_load_level_scene()

func next_level() -> void:
	if campaign_mode:
		var idx: int = DEMO_LEVEL_ORDER.find(current_level_id)
		if idx >= 0 and idx < DEMO_LEVEL_ORDER.size() - 1:
			start_demo_level(DEMO_LEVEL_ORDER[idx + 1])
			return
		return_to_menu()
		return
	level_index += 1
	current_seed = randi()
	_load_level_scene()

func return_to_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func get_level_config() -> Dictionary:
	if campaign_mode:
		return _get_demo_level_config()
	return _get_procedural_level_config()

func get_settings() -> Dictionary:
	return settings.duplicate(true)

func update_settings(section: String, key: String, value: Variant) -> void:
	if not settings.has(section):
		return
	var section_data: Dictionary = settings[section]
	section_data[key] = value
	settings[section] = section_data
	apply_audio_settings()
	_apply_heat_runtime_settings()
	save_settings()

func reset_settings() -> void:
	settings = DEFAULT_SETTINGS.duplicate(true)
	apply_audio_settings()
	_apply_heat_runtime_settings()
	save_settings()

func apply_audio_settings() -> void:
	var general_settings: Dictionary = settings.get("general", {})
	var volume: float = clampf(float(general_settings.get("master_volume", 0.8)), 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.001)))

func save_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	for section: Variant in settings.keys():
		var section_data: Dictionary = settings[section]
		for key: Variant in section_data.keys():
			cfg.set_value(str(section), str(key), section_data[key])
	cfg.save(SETTINGS_FILE)

func load_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SETTINGS_FILE) != OK:
		return
	for section: Variant in DEFAULT_SETTINGS.keys():
		if not settings.has(section):
			settings[section] = {}
		var section_data: Dictionary = settings[section]
		var defaults: Dictionary = DEFAULT_SETTINGS[section]
		for key: Variant in defaults.keys():
			section_data[key] = cfg.get_value(str(section), str(key), defaults[key])
		settings[section] = section_data
	_apply_heat_runtime_settings()

func _load_heat_config_into_defaults() -> void:
	var file: FileAccess = FileAccess.open(HEAT_CONFIG_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var heat_defaults: Dictionary = settings.get("heat", {})
	heat_defaults["global_heat_multiplier"] = float(Dictionary(parsed).get("global_heat_multiplier", heat_defaults.get("global_heat_multiplier", 1.0)))
	settings["heat"] = heat_defaults

func _apply_heat_runtime_settings() -> void:
	var heat_settings: Dictionary = settings.get("heat", {})
	HeatEngine.set_runtime_settings({
		"difficulty": str(heat_settings.get("difficulty_preset", "normal")),
		"global_heat_multiplier": float(heat_settings.get("global_heat_multiplier", 1.0)),
		"tower_heat_tolerance_boost": float(heat_settings.get("tower_heat_tolerance_boost", 0.0)),
		"cooling_efficiency": float(heat_settings.get("cooling_efficiency", 1.0)),
		"visual_heat_feedback_intensity": float(heat_settings.get("visual_heat_feedback_intensity", 1.0)),
		"educational_heat_tooltips": bool(heat_settings.get("educational_heat_tooltips", true)),
	})

func _load_level_scene() -> void:
	get_tree().change_scene_to_file(LEVEL_SCENE)

func _load_demo_levels() -> void:
	demo_levels.clear()
	for level_id: String in DEMO_LEVEL_ORDER:
		var path: String = "res://levels/demo/%s.json" % level_id
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			demo_levels[level_id] = parsed

func _get_demo_level_config() -> Dictionary:
	var level: Dictionary = demo_levels.get(current_level_id, {})
	var raw_points: Array = level.get("path_points", [[40, 640], [680, 640]])
	var packed_points: PackedVector2Array = PackedVector2Array()
	for entry: Variant in raw_points:
		if typeof(entry) == TYPE_ARRAY and Array(entry).size() >= 2:
			var point_entry: Array = entry
			packed_points.append(Vector2(float(point_entry[0]), float(point_entry[1])))
	return {
		"level_index": level_index,
		"seed": current_seed,
		"wave_count": int(level.get("wave_count", 3)),
		"enemies_per_wave": int(level.get("enemies_per_wave", 6)),
		"enemy_speed": float(level.get("enemy_speed", 120.0)),
		"spawn_interval": float(level.get("spawn_interval", 0.8)),
		"path_points": packed_points,
		"level_id": str(level.get("id", current_level_id)),
		"free_energy_threshold": float(level.get("free_energy_threshold", 0.6)),
		"minimum_bonds": int(level.get("minimum_bonds", 2)),
		"unlocked_towers": Array(level.get("unlocked_towers", [])),
		"tutorial_steps": Array(level.get("tutorial_steps", [])),
	}

func _get_procedural_level_config() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = current_seed + level_index * 101
	var pattern: int = int(rng.randi_range(0, 4))
	var game_settings: Dictionary = get_settings()
	var wave_settings: Dictionary = game_settings.get("wave", {})
	var difficulty_scale: float = float(wave_settings.get("difficulty_scale", 1.0))
	var spawn_rate_multiplier: float = float(wave_settings.get("spawn_rate_multiplier", 1.0))
	var wave_count: int = clampi(int(round((2 + level_index) * difficulty_scale)), 2, 8)
	var enemies_per_wave: int = clampi(int(round((5 + level_index * 2) * difficulty_scale)), 5, 30)
	var enemy_speed: float = (105.0 + float(level_index) * 10.0) * difficulty_scale
	var spawn_interval: float = clampf(0.8 / maxf(spawn_rate_multiplier, 0.25), 0.45, 2.0)
	return {"level_index": level_index, "seed": current_seed, "pattern": pattern, "wave_count": wave_count, "enemies_per_wave": enemies_per_wave, "enemy_speed": enemy_speed, "spawn_interval": spawn_interval, "path_points": _path_straight(rng)}

func _path_straight(rng: RandomNumberGenerator) -> PackedVector2Array:
	var mid_y: float = rng.randf_range(500.0, 780.0)
	return PackedVector2Array([Vector2(40.0, mid_y), Vector2(680.0, mid_y)])
