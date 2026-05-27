extends CanvasLayer

## In-game score readout: current score (top-left) and best score (top-right).
## Shown by Game during PLAYING / PAUSED / GAME_OVER.

var _score_label: Label
var _best_label: Label


func _ready() -> void:
	_score_label = _make_label("Score: 0", Vector2(20, 10), HORIZONTAL_ALIGNMENT_LEFT)
	_best_label = _make_label("Best: 0", Vector2(440, 10), HORIZONTAL_ALIGNMENT_RIGHT)


func set_scores(score: int, best: int) -> void:
	if _score_label != null:
		_score_label.text = "Score: %d" % score
	if _best_label != null:
		_best_label.text = "Best: %d" % best


func _make_label(text: String, pos: Vector2, align: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = Vector2(180, 24)
	label.horizontal_alignment = align
	add_child(label)
	return label
