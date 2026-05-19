extends Node2D

const InputHandlerScript := preload("res://scripts/input_handler.gd")

var body: Array[Vector2i] = []
var current_direction: int = InputHandlerScript.Direction.RIGHT
var grow_next_tick: bool = false


func _ready() -> void:
	if body.is_empty():
		_initialize_body()


func _initialize_body() -> void:
	var center := Vector2i(Grid.GRID_WIDTH / 2, Grid.GRID_HEIGHT / 2)
	var initial: Array[Vector2i] = [
		center,
		center - Vector2i(1, 0),
		center - Vector2i(2, 0),
	]
	body = initial


func move(direction: int) -> void:
	var dir_vec := direction_to_vector(direction)
	var new_head: Vector2i = body[0] + dir_vec
	body.push_front(new_head)
	if grow_next_tick:
		grow_next_tick = false
	else:
		body.pop_back()
	current_direction = direction


func schedule_growth() -> void:
	grow_next_tick = true


func get_head() -> Vector2i:
	return body[0]


func check_collision() -> bool:
	var head: Vector2i = body[0]
	if Grid.is_wall(head):
		return true
	for i in range(1, body.size()):
		if body[i] == head:
			return true
	return false


func direction_to_vector(direction: int) -> Vector2i:
	match direction:
		InputHandlerScript.Direction.UP:
			return Vector2i(0, -1)
		InputHandlerScript.Direction.DOWN:
			return Vector2i(0, 1)
		InputHandlerScript.Direction.LEFT:
			return Vector2i(-1, 0)
		InputHandlerScript.Direction.RIGHT:
			return Vector2i(1, 0)
	return Vector2i.ZERO
