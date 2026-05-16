extends Node2D

const CELL_SIZE := 32
const GRID_WIDTH := 20
const GRID_HEIGHT := 20

var position_grid: Vector2i = Vector2i(15, 10)

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(position_grid.x * CELL_SIZE, position_grid.y * CELL_SIZE, CELL_SIZE, CELL_SIZE), Color.RED, true)

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
