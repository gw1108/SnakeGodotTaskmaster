extends CanvasLayer

## Static pause overlay. Visibility toggled by Game when entering/leaving PAUSED.

const VIEWPORT_SIZE := Vector2(640, 480)


func _ready() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.size = VIEWPORT_SIZE
	add_child(dim)

	_make_label("PAUSED", 200, 40)
	_make_label("Press ESC or P to Resume", 260, 18)


func _make_label(text: String, y: float, font_size: int) -> void:
	var label := Label.new()
	label.text = text
	label.position = Vector2(0, y)
	label.size = Vector2(VIEWPORT_SIZE.x, font_size + 8)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
