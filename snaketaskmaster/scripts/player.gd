extends Node2D

const HEAD_SPRITE_PATH: String = "res://assets/sprites/player_head.png"
const BODY_SPRITE_PATH: String = "res://assets/sprites/player_body.png"

var segments: Array[Vector2i] = [
	Vector2i(10, 7),
	Vector2i(9, 7),
	Vector2i(8, 7),
]
var current_direction: Vector2i = Vector2i.RIGHT
var next_direction: Vector2i = Vector2i.RIGHT
var grow_pending: int = 0

var _head_sprite: Sprite2D
var _body_sprites: Array[Sprite2D] = []
var _head_texture: Texture2D
var _body_texture: Texture2D


func _ready() -> void:
	_head_texture = load(HEAD_SPRITE_PATH)
	_body_texture = load(BODY_SPRITE_PATH)

	_head_sprite = Sprite2D.new()
	_head_sprite.texture = _head_texture
	add_child(_head_sprite)

	for i in range(1, segments.size()):
		_body_sprites.append(_make_body_sprite())

	_sync_sprites()


func move(direction: Vector2i) -> void:
	current_direction = direction
	var new_head: Vector2i = segments[0] + direction

	if grow_pending > 0:
		segments.insert(0, new_head)
		grow_pending -= 1
		_body_sprites.append(_make_body_sprite())
	else:
		for i in range(segments.size() - 1, 0, -1):
			segments[i] = segments[i - 1]
		segments[0] = new_head

	_sync_sprites()


func add_growth() -> void:
	grow_pending += 1


func get_head_position() -> Vector2i:
	return segments[0]


func occupies_position(pos: Vector2i) -> bool:
	return segments.has(pos)


func _make_body_sprite() -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = _body_texture
	add_child(s)
	return s


func _sync_sprites() -> void:
	if _head_sprite != null:
		_head_sprite.position = GameConstants.grid_to_pixel(segments[0])
		_head_sprite.rotation = Vector2(current_direction).angle()

	for i in range(_body_sprites.size()):
		var seg_index: int = i + 1
		if seg_index < segments.size():
			_body_sprites[i].position = GameConstants.grid_to_pixel(segments[seg_index])
