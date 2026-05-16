extends Node2D

@onready var snake: Node2D = $Snake
@onready var game_tick: Timer = $GameTick

func _ready() -> void:
	game_tick.timeout.connect(_on_game_tick)

func _on_game_tick() -> void:
	snake.move()
