extends Control

@onready var version_label: Label = %VersionLabel

func _ready() -> void:
	version_label.text = "v0.00.2 – Prototype"

func _on_play_pressed() -> void:
	LevelManager.start_new_run()

func _on_settings_pressed() -> void:
	version_label.text = "Settings coming soon (audio/controls)."

func _on_quit_pressed() -> void:
	get_tree().quit()
