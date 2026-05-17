extends CanvasLayer

# Overridable so tests can point at a nonexistent path and exercise the
# guard branch without triggering a real scene change.
var game_scene_path: String = "res://scenes/game.tscn"

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
	# Guard: game scene may not exist in some test contexts. Avoid hard crash.
	if not ResourceLoader.exists(game_scene_path):
		push_warning("Title screen: %s not found" % game_scene_path)
		return
	get_tree().change_scene_to_file(game_scene_path)
