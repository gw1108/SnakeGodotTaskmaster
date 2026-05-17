extends CanvasLayer

# Overridable so tests can point at a nonexistent path and exercise the
# guard branch without triggering a real scene change.
var title_scene_path: String = "res://scenes/title_screen.tscn"

@onready var title_label: Label = $Control/VBoxContainer/TitleLabel
@onready var score_label: Label = $Control/VBoxContainer/ScoreLabel
@onready var collision_label: Label = $Control/VBoxContainer/CollisionLabel
@onready var new_high_label: Label = $Control/VBoxContainer/NewHighScoreLabel
@onready var prompt_label: Label = $Control/VBoxContainer/PromptLabel

var restarted: bool = false


func _ready() -> void:
	score_label.text = "Final Score: %d" % GameState.current_score
	new_high_label.visible = GameState.current_score > GameState.previous_high_score
	if GameState.collision_type == "":
		collision_label.visible = false
	else:
		collision_label.visible = true
		collision_label.text = _collision_message(GameState.collision_type)
	_start_blink()


func _collision_message(kind: String) -> String:
	match kind:
		"wall":
			return "You hit a wall"
		"self":
			return "You ran into yourself"
		_:
			return ""


func _start_blink() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(prompt_label, "modulate:a", 0.25, 0.6)
	tween.tween_property(prompt_label, "modulate:a", 1.0, 0.6)


func _input(event: InputEvent) -> void:
	if restarted:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		restarted = true
		restart()


func restart() -> void:
	if not ResourceLoader.exists(title_scene_path):
		push_warning("GameOver: %s not found" % title_scene_path)
		return
	get_tree().change_scene_to_file(title_scene_path)
