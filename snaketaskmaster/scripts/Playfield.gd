extends Node2D

const GRID_WIDTH := 20
const GRID_HEIGHT := 20
const CELL_SIZE := 32

const BG_COLOR := Color(0.1, 0.1, 0.1)
const GRID_COLOR := Color(0.2, 0.2, 0.2)
const BORDER_COLOR := Color.WHITE
const BORDER_THICKNESS := 3.0

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var w := GRID_WIDTH * CELL_SIZE
	var h := GRID_HEIGHT * CELL_SIZE
	draw_rect(Rect2(0, 0, w, h), BG_COLOR, true)
	for x in range(GRID_WIDTH + 1):
		draw_line(Vector2(x * CELL_SIZE, 0), Vector2(x * CELL_SIZE, h), GRID_COLOR)
	for y in range(GRID_HEIGHT + 1):
		draw_line(Vector2(0, y * CELL_SIZE), Vector2(w, y * CELL_SIZE), GRID_COLOR)
	draw_rect(Rect2(0, 0, w, h), BORDER_COLOR, false, BORDER_THICKNESS)
