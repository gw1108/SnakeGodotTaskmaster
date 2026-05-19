extends Node

const CELL_SIZE := 32
const GRID_WIDTH := 18
const GRID_HEIGHT := 13


func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos * CELL_SIZE) + Vector2(CELL_SIZE, CELL_SIZE) * 0.5


func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i((world_pos / float(CELL_SIZE)).floor())


func is_wall(grid_pos: Vector2i) -> bool:
	return grid_pos.x == 0 \
		or grid_pos.x == GRID_WIDTH + 1 \
		or grid_pos.y == 0 \
		or grid_pos.y == GRID_HEIGHT + 1


func get_interior_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(1, GRID_WIDTH + 1):
		for y in range(1, GRID_HEIGHT + 1):
			cells.append(Vector2i(x, y))
	return cells
