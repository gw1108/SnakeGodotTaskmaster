class_name Food
extends Node2D

const FOOD_TEXTURE: Texture2D = preload("res://sprites/food.png")

var position_grid: Vector2i = Vector2i.ZERO

var _sprite: Sprite2D


func _ready() -> void:
	if _sprite == null:
		_ensure_sprite()


func spawn(arena: Arena, snake_body: Array[Vector2i]) -> void:
	_ensure_sprite()
	var valid_cells: Array[Vector2i] = []
	for x in range(1, arena.grid_width - 1):
		for y in range(1, arena.grid_height - 1):
			var cell := Vector2i(x, y)
			if snake_body.has(cell):
				continue
			valid_cells.append(cell)
	if valid_cells.is_empty():
		return
	position_grid = valid_cells.pick_random()
	_sprite.position = arena.grid_to_world(position_grid)


func get_grid_pos() -> Vector2i:
	return position_grid


func _ensure_sprite() -> void:
	if _sprite != null:
		return
	_sprite = Sprite2D.new()
	_sprite.texture = FOOD_TEXTURE
	add_child(_sprite)
