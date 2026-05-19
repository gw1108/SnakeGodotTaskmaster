extends Node2D

const GameStateMachineScript := preload("res://scripts/game_state_machine.gd")

@onready var playfield: Node2D = $Playfield
@onready var hud: CanvasLayer = $HUD
@onready var state_machine: Node = $GameStateMachine
@onready var game_tick: Node = $GameTick
@onready var eat_sound: AudioStreamPlayer = $EatSound
@onready var death_sound: AudioStreamPlayer = $DeathSound

var score: int = 0


func _ready() -> void:
	if state_machine != null and not state_machine.state_changed.is_connected(_on_state_changed):
		state_machine.state_changed.connect(_on_state_changed)
	if hud != null:
		hud.update_score(score)
		hud.hide_game_over()
	var food := get_node_or_null("Food")
	if food != null and food.has_signal("food_eaten") and not food.food_eaten.is_connected(_on_food_eaten):
		food.food_eaten.connect(_on_food_eaten)


func _on_food_eaten() -> void:
	if eat_sound != null and eat_sound.stream != null:
		eat_sound.play()


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
	if new_state == GameStateMachineScript.State.GAME_OVER:
		if hud != null:
			hud.show_game_over(score)
		if death_sound != null and death_sound.stream != null:
			death_sound.play()
	elif new_state == GameStateMachineScript.State.PLAYING:
		if hud != null:
			hud.hide_game_over()
