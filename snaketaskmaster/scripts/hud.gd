class_name HUD
extends CanvasLayer

@onready var _score_label: Label = $ScoreLabel

var score: int = 0


func update_score(new_score: int) -> void:
	score = new_score
	_score_label.text = "Score: " + str(score)


func reset() -> void:
	update_score(0)
