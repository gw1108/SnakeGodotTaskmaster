class_name Grid
## Grid-based coordinate system for the arena.
##
## Defines the arena dimensions and cell size, and provides conversions
## between grid cells (Vector2i) and pixel positions (Vector2), plus
## bounds and border checks. All members are static — reference as
## `Grid.CELL_SIZE`, `Grid.cell_to_pixel(...)`, etc.

const CELL_SIZE := 32
const GRID_WIDTH := 20
const GRID_HEIGHT := 15

## Returns the top-left pixel corner of the given cell.
static func cell_to_pixel(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE)

## Returns the cell containing the given pixel position.
## Uses floored division so negative positions map correctly.
static func pixel_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / CELL_SIZE), floori(pos.y / CELL_SIZE))

## True if the cell is within the arena bounds.
static func is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < GRID_WIDTH and cell.y >= 0 and cell.y < GRID_HEIGHT

## True if the cell lies on the outer edge of the arena.
static func is_border_cell(cell: Vector2i) -> bool:
	return cell.x == 0 or cell.x == GRID_WIDTH - 1 or cell.y == 0 or cell.y == GRID_HEIGHT - 1
