extends Control

@onready var version_label: Label = %VersionLabel
@onready var seed_input: LineEdit = %SeedInput

func _ready() -> void:
	version_label.text = "v0.00.2 – Prototype"
	seed_input.placeholder_text = "Seed (e.g. DRAGON42)"

func _on_play_pressed() -> void:
	LevelManager.start_new_run(seed_input.text)

func _on_settings_pressed() -> void:
	version_label.text = "Settings coming soon (audio/controls)."

func _on_quit_pressed() -> void:
	get_tree().quit()
