extends Node2D

const GRID_WIDTH := 20
const GRID_HEIGHT := 20
const CELL_SIZE := 32

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var w := GRID_WIDTH * CELL_SIZE
	var h := GRID_HEIGHT * CELL_SIZE
	draw_rect(Rect2(0, 0, w, h), Color.BLACK, true)
	var grid_color := Color(0.2, 0.2, 0.2)
	for x in range(GRID_WIDTH + 1):
		draw_line(Vector2(x * CELL_SIZE, 0), Vector2(x * CELL_SIZE, h), grid_color)
	for y in range(GRID_HEIGHT + 1):
		draw_line(Vector2(0, y * CELL_SIZE), Vector2(w, y * CELL_SIZE), grid_color)
	draw_rect(Rect2(0, 0, w, h), Color.WHITE, false, 2.0)
