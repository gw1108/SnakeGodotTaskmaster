extends CanvasLayer

## Game-over screen: final score, best score, a conditional "New Best!" banner,
## and the restart prompt. Game calls set_scores() and show_new_best() on entry.

const VIEWPORT_SIZE := Vector2(640, 480)

var _score_label: Label
var _best_label: Label
var _new_best_label: Label


func _ready() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.size = VIEWPORT_SIZE
	add_child(dim)

	_make_label("GAME OVER", 150, 40)
	_score_label = _make_label("Score: 0", 220, 22)
	_best_label = _make_label("Best: 0", 252, 22)
	_new_best_label = _make_label("New Best!", 290, 22)
	_new_best_label.visible = false
	_make_label("Press ENTER to Restart", 340, 18)


func set_scores(score: int, best: int) -> void:
	if _score_label != null:
		_score_label.text = "Score: %d" % score
	if _best_label != null:
		_best_label.text = "Best: %d" % best


func show_new_best(is_best: bool) -> void:
	if _new_best_label != null:
		_new_best_label.visible = is_best


func _make_label(text: String, y: float, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = Vector2(0, y)
	label.size = Vector2(VIEWPORT_SIZE.x, font_size + 8)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
	return label
