extends Control

@onready var high_score_label: Label = $VBoxContainer/HighScoreLabel
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready() -> void:
	high_score_label.text = "High Score: " + str(HighScore.get_high_score())
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	start_button.grab_focus()

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
