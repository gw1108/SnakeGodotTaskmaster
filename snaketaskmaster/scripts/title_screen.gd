extends CanvasLayer

const GAME_SCENE_PATH := "res://scenes/game.tscn"

@onready var title_label: Label = $Control/VBoxContainer/TitleLabel
@onready var high_score_label: Label = $Control/VBoxContainer/HighScoreLabel
@onready var prompt_label: Label = $Control/VBoxContainer/PromptLabel

var started: bool = false


func _ready() -> void:
	refresh_high_score()
	_start_blink()


func refresh_high_score() -> void:
	high_score_label.text = "High Score: %d" % GameState.high_score


func _start_blink() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(prompt_label, "modulate:a", 0.25, 0.6)
	tween.tween_property(prompt_label, "modulate:a", 1.0, 0.6)


func _input(event: InputEvent) -> void:
	if started:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		started = true
		start_game()


func start_game() -> void:
	# Guard: game scene comes from a later task. Avoid a hard crash when missing.
	if not ResourceLoader.exists(GAME_SCENE_PATH):
		push_warning("Title screen: %s not found yet" % GAME_SCENE_PATH)
		return
	get_tree().change_scene_to_file(GAME_SCENE_PATH)
