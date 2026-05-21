class_name Snake
extends Node2D

signal food_eaten
signal died

const HEAD_TEXTURE: Texture2D = preload("res://sprites/player_head.png")
const BODY_TEXTURE: Texture2D = preload("res://sprites/player_body.png")

@export var starting_length: int = 3
@export var starting_head: Vector2i = Vector2i(5, 7)

var body: Array[Vector2i] = []
var heading: Vector2i = Vector2i.RIGHT
var queued_direction: Vector2i = Vector2i.RIGHT
var is_alive: bool = true

var _sprites: Array[Sprite2D] = []


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
	update_visuals(arena)


func update_visuals(arena: Arena) -> void:
	while _sprites.size() < body.size():
		var sprite := Sprite2D.new()
		add_child(sprite)
		_sprites.append(sprite)
	while _sprites.size() > body.size():
		var extra: Sprite2D = _sprites.pop_back()
		remove_child(extra)
		extra.queue_free()
	for i in body.size():
		var sprite := _sprites[i]
		sprite.texture = HEAD_TEXTURE if i == 0 else BODY_TEXTURE
		sprite.position = arena.grid_to_world(body[i])
		sprite.rotation = _heading_to_angle(heading) if i == 0 else 0.0


static func _heading_to_angle(h: Vector2i) -> float:
	if h == Vector2i.RIGHT:
		return 0.0
	if h == Vector2i.DOWN:
		return PI / 2.0
	if h == Vector2i.LEFT:
		return PI
	return -PI / 2.0
