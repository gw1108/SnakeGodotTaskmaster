extends CanvasLayer

## Title screen: game name, persisted best score, and start prompt.
## Shown by Game in TITLE mode; Game calls set_best() on entry.

const VIEWPORT_WIDTH := 640

var _best_label: Label


func _ready() -> void:
	_make_label("SNAKE", 180, 48)
	_best_label = _make_label("Best: 0", 260, 20)
	_make_label("Press ENTER to Start", 320, 20)


func set_best(best: int) -> void:
	if _best_label != null:
		_best_label.text = "Best: %d" % best


func _make_label(text: String, y: float, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = Vector2(0, y)
	label.size = Vector2(VIEWPORT_WIDTH, font_size + 8)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
	return label
