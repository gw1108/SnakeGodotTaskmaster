extends Node2D

const CELL_SIZE := 32

var position_grid: Vector2i = Vector2i(15, 10)

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(position_grid.x * CELL_SIZE, position_grid.y * CELL_SIZE, CELL_SIZE, CELL_SIZE), Color.RED, true)
