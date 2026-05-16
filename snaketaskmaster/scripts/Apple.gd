extends Node2D

const CELL_SIZE := 32
const GRID_WIDTH := 20
const GRID_HEIGHT := 20

const APPLE_COLOR := Color(0.9, 0.2, 0.2)
const HIGHLIGHT_COLOR := Color(1.0, 0.6, 0.6)
const CELL_PADDING := 2

var position_grid: Vector2i = Vector2i(15, 10)

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var px := position_grid.x * CELL_SIZE
	var py := position_grid.y * CELL_SIZE
	var center := Vector2(px + CELL_SIZE * 0.5, py + CELL_SIZE * 0.5)
	var radius := (CELL_SIZE - CELL_PADDING * 2) * 0.5
	draw_circle(center, radius, APPLE_COLOR)
	# Subtle highlight for visual polish.
	draw_circle(center + Vector2(-radius * 0.35, -radius * 0.35), radius * 0.25, HIGHLIGHT_COLOR)

func respawn(snake_body: Array[Vector2i]) -> void:
	var empty_cells: Array[Vector2i] = []
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			var cell := Vector2i(x, y)
			if not snake_body.has(cell):
				empty_cells.append(cell)
	if empty_cells.size() > 0:
		position_grid = empty_cells[randi() % empty_cells.size()]
		queue_redraw()
