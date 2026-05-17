extends Node

const GRID_WIDTH: int = 20
const GRID_HEIGHT: int = 15
const CELL_SIZE: int = 32
const TICK_INTERVAL: float = 0.15


func grid_to_pixel(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * CELL_SIZE + CELL_SIZE / 2.0,
		grid_pos.y * CELL_SIZE + CELL_SIZE / 2.0
	)


func pixel_to_grid(pixel_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(pixel_pos.x / CELL_SIZE)),
		int(floor(pixel_pos.y / CELL_SIZE))
	)


func is_valid_grid_pos(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < GRID_WIDTH and pos.y >= 0 and pos.y < GRID_HEIGHT
