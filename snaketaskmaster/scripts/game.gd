extends Node2D

# Overridable so tests can point at a nonexistent path and exercise the
# guard branch without triggering a real scene change.
var game_over_scene_path: String = "res://scenes/game_over_screen.tscn"

@onready var playfield: Node2D = $Playfield
@onready var player: Node2D = $Player
@onready var food_manager: Node2D = $FoodManager
@onready var game_loop: Node = $GameLoop
@onready var score_label: Label = $HUD/ScoreLabel
@onready var eat_sound: AudioStreamPlayer = $EatSound
@onready var death_sound: AudioStreamPlayer = $DeathSound


func _ready() -> void:
	GameState.reset()
	game_loop.player = player
	game_loop.food_manager = food_manager
	game_loop.food_eaten.connect(_on_food_eaten)
	game_loop.wall_collision.connect(_on_game_over)
	game_loop.self_collision.connect(_on_game_over)
	food_manager.spawn_food(player.segments)
	_refresh_score()
	game_loop.start_game()


func _refresh_score() -> void:
	score_label.text = "Score: %d" % GameState.current_score


func _on_food_eaten() -> void:
	_refresh_score()
	if eat_sound != null and eat_sound.stream != null:
		eat_sound.play()


func _on_game_over() -> void:
	if death_sound != null and death_sound.stream != null:
		death_sound.play()
	if not ResourceLoader.exists(game_over_scene_path):
		push_warning("Game: %s not found" % game_over_scene_path)
		return
	await get_tree().create_timer(0.5).timeout
	if is_inside_tree():
		get_tree().change_scene_to_file(game_over_scene_path)
