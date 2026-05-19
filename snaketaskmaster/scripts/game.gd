extends Node2D

const GameStateMachineScript := preload("res://scripts/game_state_machine.gd")

@onready var playfield: Node2D = $Playfield
@onready var hud: CanvasLayer = $HUD
@onready var state_machine: Node = $GameStateMachine
@onready var game_tick: Node = $GameTick

var score: int = 0


func _ready() -> void:
	if state_machine != null and not state_machine.state_changed.is_connected(_on_state_changed):
		state_machine.state_changed.connect(_on_state_changed)
	if hud != null:
		hud.update_score(score)
		hud.hide_game_over()


func _input(event: InputEvent) -> void:
	if state_machine == null:
		return
	if state_machine.current_state != GameStateMachineScript.State.GAME_OVER:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		restart()


func restart() -> void:
	score = 0
	var snake := get_node_or_null("Snake")
	if snake != null and snake.has_method("reset"):
		snake.reset()
	var food := get_node_or_null("Food")
	if food != null and food.has_method("spawn"):
		var occupied: Array[Vector2i] = []
		if snake != null and "body" in snake:
			for cell in snake.body:
				occupied.append(cell)
		food.spawn(occupied)
	if hud != null:
		hud.update_score(0)
		hud.hide_game_over()
	if state_machine != null:
		state_machine.transition_to(GameStateMachineScript.State.PLAYING)


func _on_state_changed(new_state: int) -> void:
	if hud == null:
		return
	if new_state == GameStateMachineScript.State.GAME_OVER:
		hud.show_game_over(score)
	elif new_state == GameStateMachineScript.State.PLAYING:
		hud.hide_game_over()
