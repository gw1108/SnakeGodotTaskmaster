extends Node2D

@onready var snake: Node2D = $Snake
@onready var game_tick: Timer = $GameTick

func _ready() -> void:
	game_tick.timeout.connect(_on_game_tick)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		snake.queue_direction(Vector2i(0, -1))
	elif event.is_action_pressed("move_down"):
		snake.queue_direction(Vector2i(0, 1))
	elif event.is_action_pressed("move_left"):
		snake.queue_direction(Vector2i(-1, 0))
	elif event.is_action_pressed("move_right"):
		snake.queue_direction(Vector2i(1, 0))

func _on_game_tick() -> void:
	snake.move()
