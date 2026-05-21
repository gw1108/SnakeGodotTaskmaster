class_name Gameplay
extends Node2D

const GAME_OVER_SCENE_PATH: String = "res://scenes/GameOver.tscn"

@onready var arena: Arena = $Arena
@onready var snake: Snake = $Snake
@onready var food: Food = $Food
@onready var hud: HUD = $HUD
@onready var tick_timer: Timer = $TickTimer
@onready var death_timer: Timer = $DeathTimer

var score: int = 0


func _ready() -> void:
	snake.food_eaten.connect(_on_food_eaten)
	snake.died.connect(_on_snake_died)
	food.spawn(arena, snake.body)
	snake.update_visuals(arena)
	hud.reset()
	tick_timer.timeout.connect(_on_tick)
	death_timer.timeout.connect(_on_death_timeout)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		snake.queue_direction(Vector2i.UP)
	elif event.is_action_pressed("move_down"):
		snake.queue_direction(Vector2i.DOWN)
	elif event.is_action_pressed("move_left"):
		snake.queue_direction(Vector2i.LEFT)
	elif event.is_action_pressed("move_right"):
		snake.queue_direction(Vector2i.RIGHT)


func _on_tick() -> void:
	snake.tick(arena, food.get_grid_pos())


func _on_food_eaten() -> void:
	score += 1
	hud.update_score(score)
	food.spawn(arena, snake.body)


func _on_snake_died() -> void:
	tick_timer.stop()
	GameState.set_score(score)
	death_timer.start()


func _on_death_timeout() -> void:
	if ResourceLoader.exists(GAME_OVER_SCENE_PATH):
		get_tree().change_scene_to_file(GAME_OVER_SCENE_PATH)
