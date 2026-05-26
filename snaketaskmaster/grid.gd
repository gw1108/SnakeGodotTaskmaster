extends Node
## Grid model autoload. Defines the play-field dimensions and converts between
## grid coordinates (Vector2i cells) and world positions (Vector2 pixels).
## 20x15 cells at 32px maps exactly onto the 640x480 viewport.

const GRID_WIDTH: int = 20
const GRID_HEIGHT: int = 15
const CELL_SIZE: int = 32


func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * CELL_SIZE, grid_pos.y * CELL_SIZE)


func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / CELL_SIZE), int(world_pos.y / CELL_SIZE))


func is_in_bounds(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < GRID_WIDTH \
		and grid_pos.y >= 0 and grid_pos.y < GRID_HEIGHT
