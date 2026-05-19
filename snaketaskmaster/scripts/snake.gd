extends Node2D

const InputHandlerScript := preload("res://scripts/input_handler.gd")
const HEAD_TEXTURE_PATH := "res://source/sprites/player_head.png"
const BODY_TEXTURE_PATH := "res://source/sprites/player_body.png"

var body: Array[Vector2i] = []
var current_direction: int = InputHandlerScript.Direction.RIGHT
var grow_next_tick: bool = false

var head_sprite: Sprite2D
var body_sprites: Array[Sprite2D] = []


func _ready() -> void:
	if body.is_empty():
		_initialize_body()
	_init_rendering()
	_update_rendering()


func _initialize_body() -> void:
	var center := Vector2i(Grid.GRID_WIDTH / 2, Grid.GRID_HEIGHT / 2)
	var initial: Array[Vector2i] = [
		center,
		center - Vector2i(1, 0),
		center - Vector2i(2, 0),
	]
	body = initial


func _init_rendering() -> void:
	head_sprite = Sprite2D.new()
	head_sprite.texture = load(HEAD_TEXTURE_PATH)
	add_child(head_sprite)


func _make_body_sprite() -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(BODY_TEXTURE_PATH)
	add_child(s)
	return s


func _update_rendering() -> void:
	if head_sprite == null:
		return
	head_sprite.position = Grid.grid_to_world(body[0])
	head_sprite.rotation = Vector2(direction_to_vector(current_direction)).angle()
	var needed: int = max(body.size() - 1, 0)
	while body_sprites.size() < needed:
		body_sprites.append(_make_body_sprite())
	while body_sprites.size() > needed:
		var extra: Sprite2D = body_sprites.pop_back()
		extra.queue_free()
	for i in range(needed):
		body_sprites[i].position = Grid.grid_to_world(body[i + 1])


func move(direction: int) -> void:
	var dir_vec := direction_to_vector(direction)
	var new_head: Vector2i = body[0] + dir_vec
	body.push_front(new_head)
	if grow_next_tick:
		grow_next_tick = false
	else:
		body.pop_back()
	current_direction = direction
	_update_rendering()


func schedule_growth() -> void:
	grow_next_tick = true


func reset() -> void:
	_initialize_body()
	current_direction = InputHandlerScript.Direction.RIGHT
	grow_next_tick = false
	_update_rendering()


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
