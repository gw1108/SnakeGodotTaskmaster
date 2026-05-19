extends Node

enum Direction { UP, DOWN, LEFT, RIGHT }

var current_direction: int = Direction.RIGHT
var buffered_direction: Variant = null


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_buffer_direction(Direction.UP)
	elif event.is_action_pressed("move_down"):
		_buffer_direction(Direction.DOWN)
	elif event.is_action_pressed("move_left"):
		_buffer_direction(Direction.LEFT)
	elif event.is_action_pressed("move_right"):
		_buffer_direction(Direction.RIGHT)


func _buffer_direction(dir: int) -> void:
	if not _is_opposite(dir, current_direction):
		buffered_direction = dir


func _is_opposite(a: int, b: int) -> bool:
	return (a == Direction.UP and b == Direction.DOWN) \
		or (a == Direction.DOWN and b == Direction.UP) \
		or (a == Direction.LEFT and b == Direction.RIGHT) \
		or (a == Direction.RIGHT and b == Direction.LEFT)


func consume_buffered_direction() -> int:
	if buffered_direction != null:
		current_direction = buffered_direction
		buffered_direction = null
	return current_direction
