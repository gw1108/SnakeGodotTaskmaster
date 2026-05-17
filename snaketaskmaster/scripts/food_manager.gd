extends Node2D

signal food_eaten

const FOOD_SPRITE_PATH: String = "res://assets/sprites/food.png"

var current_food_position: Vector2i = Vector2i(-1, -1)
var food_sprite: Sprite2D


func _ready() -> void:
	food_sprite = Sprite2D.new()
	food_sprite.texture = load(FOOD_SPRITE_PATH)
	add_child(food_sprite)
	food_sprite.visible = false


func spawn_food(occupied_cells: Array[Vector2i]) -> bool:
	var available: Array[Vector2i] = []
	for x in range(GameConstants.GRID_WIDTH):
		for y in range(GameConstants.GRID_HEIGHT):
			var cell := Vector2i(x, y)
			if occupied_cells.has(cell):
				continue
			available.append(cell)

	if available.is_empty():
		return false

	var pick: Vector2i = available[randi() % available.size()]
	current_food_position = pick
	if food_sprite != null:
		food_sprite.position = GameConstants.grid_to_pixel(pick)
		food_sprite.visible = true
	return true


func check_collision(head_pos: Vector2i) -> bool:
	if head_pos == current_food_position:
		food_eaten.emit()
		return true
	return false
