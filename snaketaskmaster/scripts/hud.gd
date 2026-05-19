extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var final_score_label: Label = $GameOverPanel/VBoxContainer/FinalScoreLabel


func update_score(new_score: int) -> void:
	if score_label == null:
		return
	score_label.text = "Score: %d" % new_score


func show_game_over(final_score: int) -> void:
	if game_over_panel == null:
		return
	game_over_panel.visible = true
	if final_score_label != null:
		final_score_label.text = "Final Score: %d" % final_score


func hide_game_over() -> void:
	if game_over_panel == null:
		return
	game_over_panel.visible = false
