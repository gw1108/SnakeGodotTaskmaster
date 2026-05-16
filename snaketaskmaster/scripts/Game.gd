extends Node2D

@onready var snake: Node2D = $Snake
@onready var apple: Node2D = $Apple
@onready var game_tick: Timer = $GameTick
@onready var score_label: Label = $HUD/ScoreLabel

var is_game_over: bool = false
var score: int = 0

func _ready() -> void:
	game_tick.timeout.connect(_on_game_tick)
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if is_game_over:
		if event.is_action_pressed("ui_accept"):
			get_tree().reload_current_scene()
		return
	if event.is_action_pressed("move_up"):
		snake.queue_direction(Vector2i(0, -1))
	elif event.is_action_pressed("move_down"):
		snake.queue_direction(Vector2i(0, 1))
	elif event.is_action_pressed("move_left"):
		snake.queue_direction(Vector2i(-1, 0))
	elif event.is_action_pressed("move_right"):
		snake.queue_direction(Vector2i(1, 0))

func _on_game_tick() -> void:
	if is_game_over:
		return
	snake.move()
	if snake.check_collision():
		_game_over()
		return
	if snake.body[0] == apple.position_grid:
		snake.grow()
		apple.respawn(snake.body)
		score += 1
		_update_hud()

func _update_hud() -> void:
	score_label.text = "Score: " + str(score)

func _game_over() -> void:
	is_game_over = true
	game_tick.stop()
	print("Game Over! Press Space/Enter to restart")
