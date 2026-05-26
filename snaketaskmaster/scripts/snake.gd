class_name Snake
## Snake data model: an ordered list of grid cells with the head first.
##
## `body[0]` is the head; the tail is the last element. `direction` is the
## current movement step, always one of Vector2i.UP/DOWN/LEFT/RIGHT. This is a
## pure data object (no node, no rendering) so it can be unit-tested directly.

## Segments from head (index 0) to tail (last index).
var body: Array[Vector2i] = []
## Current movement direction (a unit grid step).
var direction := Vector2i.RIGHT

## Spawns a 3-segment snake at the arena center, facing right.
## The tail trails to the left so the first move_forward() advances cleanly.
func _init() -> void:
	var start := Vector2i(Grid.GRID_WIDTH / 2, Grid.GRID_HEIGHT / 2)
	body = [start, start - Vector2i.RIGHT, start - Vector2i.RIGHT * 2]

## Returns the head cell (body[0]).
func get_head() -> Vector2i:
	return body[0]

## Advances one cell: inserts a new head ahead and drops the tail (length stays).
func move_forward() -> void:
	body.insert(0, body[0] + direction)
	body.pop_back()

## Like move_forward() but keeps the tail, so the snake grows by one segment.
func grow() -> void:
	body.insert(0, body[0] + direction)

## Sets the movement direction, rejecting a 180-degree reversal while the snake
## has more than one segment (which would otherwise drive it into its own neck).
func set_direction(new_dir: Vector2i) -> void:
	if body.size() > 1 and new_dir == -direction:
		return
	direction = new_dir

## True if the head occupies the same cell as any other body segment.
func is_colliding_with_self() -> bool:
	return body.slice(1).has(body[0])
