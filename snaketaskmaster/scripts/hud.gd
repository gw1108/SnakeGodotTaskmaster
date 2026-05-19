extends CanvasLayer

@onready var score_label: Label = $ScoreLabel


func update_score(new_score: int) -> void:
	if score_label == null:
		return
	score_label.text = "Score: %d" % new_score
