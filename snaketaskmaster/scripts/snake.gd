class_name Snake
extends Node2D

signal food_eaten
signal died

@export var starting_length: int = 3
@export var starting_head: Vector2i = Vector2i(5, 7)

var body: Array[Vector2i] = []
var heading: Vector2i = Vector2i.RIGHT
var queued_direction: Vector2i = Vector2i.RIGHT
var is_alive: bool = true


func _ready() -> void:
	reset()


func reset() -> void:
	body.clear()
	for i in starting_length:
		body.append(Vector2i(starting_head.x - i, starting_head.y))
	heading = Vector2i.RIGHT
	queued_direction = Vector2i.RIGHT
	is_alive = true


func queue_direction(dir: Vector2i) -> void:
	if dir == -heading:
		return
	queued_direction = dir


func tick(arena: Arena, food_pos: Vector2i) -> void:
	if not is_alive:
		return
	heading = queued_direction
	var new_head: Vector2i = body[0] + heading
	if arena.is_wall(new_head) or body.has(new_head):
		is_alive = false
		died.emit()
		return
	body.push_front(new_head)
	if new_head == food_pos:
		food_eaten.emit()
	else:
		body.pop_back()
