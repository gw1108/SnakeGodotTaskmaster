class_name Snake
extends Node2D
## Snake model. Holds the body as an ordered array of grid cells where body[0]
## is the head, and advances one cell per tick in the current direction. Each
## frame it mirrors the body onto a pool of Sprite2D nodes for rendering.

const HEAD_TEXTURE: Texture2D = preload("res://sprites/player_head.png")
const BODY_TEXTURE: Texture2D = preload("res://sprites/player_body.png")

## Body cells, head first. Starts length 3 centered horizontally on the grid.
var body: Array[Vector2i] = []
## Current heading; one cell is added to the head each move().
var direction: Vector2i = Vector2i.RIGHT
## Number of pending growth steps. While > 0, move() skips the tail removal.
var grow_pending: int = 0

## Sprite for body[0]; the body_sprites pool covers body[1..].
var head_sprite: Sprite2D
var body_sprites: Array[Sprite2D] = []


func _init() -> void:
	body = [Vector2i(10, 7), Vector2i(9, 7), Vector2i(8, 7)]


func _ready() -> void:
	head_sprite = _make_sprite(HEAD_TEXTURE)


## Keep the sprites following the body model every frame.
func _process(_delta: float) -> void:
	head_sprite.position = _cell_to_world_center(body[0])
	_update_body_sprites()


## Grow or shrink the body sprite pool to one per non-head cell, then place each.
func _update_body_sprites() -> void:
	while body_sprites.size() < body.size() - 1:
		body_sprites.append(_make_sprite(BODY_TEXTURE))
	while body_sprites.size() > body.size() - 1:
		body_sprites.pop_back().queue_free()
	for i in range(body_sprites.size()):
		body_sprites[i].position = _cell_to_world_center(body[i + 1])


## Build a pixel-art Sprite2D (nearest filtering) and parent it to the snake.
func _make_sprite(texture: Texture2D) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	return sprite


## grid_to_world() yields a cell's top-left; Sprite2D is centered, so nudge by
## half a cell to seat the sprite squarely over its grid tile.
func _cell_to_world_center(cell: Vector2i) -> Vector2:
	return Grid.grid_to_world(cell) + Vector2(Grid.CELL_SIZE, Grid.CELL_SIZE) * 0.5


## Advance one cell: prepend a new head, then drop the tail unless growing.
func move() -> void:
	var new_head: Vector2i = body[0] + direction
	body.insert(0, new_head)
	if grow_pending > 0:
		grow_pending -= 1
	else:
		body.pop_back()


## Change heading, ignoring 180-degree reversals into the neck and the zero
## vector so the snake can never instantly fold back on itself.
func set_direction(new_dir: Vector2i) -> void:
	if new_dir != -direction and new_dir != Vector2i.ZERO:
		direction = new_dir


## Queue one cell of growth, applied on the next move().
func grow() -> void:
	grow_pending += 1


func get_head() -> Vector2i:
	return body[0]


## True when the head overlaps any other body cell.
func check_self_collision() -> bool:
	for i in range(1, body.size()):
		if body[i] == body[0]:
			return true
	return false
