class_name TitleScreen
extends Control

const GAMEPLAY_SCENE_PATH: String = "res://scenes/Gameplay.tscn"

signal start_game_requested


func _ready() -> void:
	start_game_requested.connect(_on_start_game_requested)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("start"):
		start_game_requested.emit()


func _on_start_game_requested() -> void:
	get_tree().change_scene_to_file(GAMEPLAY_SCENE_PATH)
