extends Node2D

@onready var snake: Node2D = $Snake
@onready var apple: Node2D = $Apple
@onready var game_tick: Timer = $GameTick
@onready var score_label: Label = $HUD/ScoreLabel
@onready var game_over_overlay: CanvasLayer = $GameOverOverlay
@onready var final_score_label: Label = $GameOverOverlay/VBoxContainer/FinalScoreLabel
@onready var game_over_high_label: Label = $GameOverOverlay/VBoxContainer/HighScoreLabel
@onready var new_best_label: Label = $GameOverOverlay/VBoxContainer/NewBestLabel
@onready var restart_button: Button = $GameOverOverlay/VBoxContainer/RestartButton
@onready var menu_button: Button = $GameOverOverlay/VBoxContainer/MenuButton
@onready var pause_overlay: CanvasLayer = $PauseOverlay

var is_game_over: bool = false
var is_paused: bool = false
var score: int = 0

func _ready() -> void:
	game_tick.timeout.connect(_on_game_tick)
	restart_button.pressed.connect(_restart_game)
	menu_button.pressed.connect(_return_to_menu)
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if is_game_over:
		return
	if event.is_action_pressed("pause"):
		_toggle_pause()
		return
	if is_paused:
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

func _toggle_pause() -> void:
	is_paused = not is_paused
	pause_overlay.visible = is_paused
	get_tree().paused = is_paused

func _game_over() -> void:
	is_game_over = true
	game_tick.stop()
	var old_high: int = HighScore.get_high_score()
	HighScore.save_high_score(score)
	var new_high: int = HighScore.get_high_score()
	_show_game_over_screen(old_high, new_high)

func _show_game_over_screen(old_high: int, new_high: int) -> void:
	final_score_label.text = "Score: " + str(score)
	game_over_high_label.text = "High Score: " + str(new_high)
	new_best_label.visible = new_high > old_high
	game_over_overlay.visible = true
	restart_button.grab_focus()

func _restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _return_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
