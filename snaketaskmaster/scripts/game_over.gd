class_name GameOver
extends Control

const GAMEPLAY_SCENE_PATH: String = "res://scenes/Gameplay.tscn"

signal restart_requested

var final_score: int = 0


func _ready() -> void:
	set_score(GameState.get_score())
	restart_requested.connect(_on_restart_requested)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		restart_requested.emit()


func set_score(score: int) -> void:
	final_score = score
	if is_inside_tree():
		var label: Label = $VBoxContainer/ScoreLabel
		label.text = "Score: %d" % final_score


func _on_restart_requested() -> void:
	get_tree().change_scene_to_file(GAMEPLAY_SCENE_PATH)
