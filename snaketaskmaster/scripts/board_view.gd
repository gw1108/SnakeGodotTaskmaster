extends Node2D

## Renders the current GameState as pixel art and plays brief eat/death flashes.
## Reads game state (set by Game), never mutates it. Source sprites are 32px;
## they are scaled to TILE_PX (16) tiles via draw_texture_rect so the 25x25
## board fits the 640x480 viewport with the HUD above it.

const FLOOR := preload("res://sprites/floor_tile.png")
const WALL := preload("res://sprites/wall_tile.png")
const HEAD := preload("res://sprites/player_head.png")
const BODY := preload("res://sprites/player_body.png")
const FOOD := preload("res://sprites/food.png")

const TILE_PX := 16
const BOARD_ORIGIN := Vector2(120, 40)

var _state: GameState = null


func _draw() -> void:
	if _state == null:
		return
	var b := _state.bounds

	# Floor.
	for y in b.y:
		for x in b.x:
			draw_texture_rect(FLOOR, _tile_rect(Vector2i(x, y)), false)

	# Border walls: a one-tile ring just outside the play area.
	for x in range(-1, b.x + 1):
		draw_texture_rect(WALL, _tile_rect(Vector2i(x, -1)), false)
		draw_texture_rect(WALL, _tile_rect(Vector2i(x, b.y)), false)
	for y in b.y:
		draw_texture_rect(WALL, _tile_rect(Vector2i(-1, y)), false)
		draw_texture_rect(WALL, _tile_rect(Vector2i(b.x, y)), false)

	# Snake: distinct head at index 0, body for the rest.
	for i in _state.snake.size():
		var tex: Texture2D = HEAD if i == 0 else BODY
		draw_texture_rect(tex, _tile_rect(_state.snake[i]), false)

	# Apple.
	if _state.apple != GameState.NO_APPLE:
		draw_texture_rect(FOOD, _tile_rect(_state.apple), false)


## Request a redraw (called by Game after each tick / on transitions).
func refresh() -> void:
	queue_redraw()


func flash_eat() -> void:
	_flash(Color(1.3, 1.3, 1.3), 0.08)


func flash_death() -> void:
	_flash(Color(1.0, 0.4, 0.4), 0.2)


func _flash(color: Color, duration: float) -> void:
	modulate = color
	var timer := get_tree().create_timer(duration)
	timer.timeout.connect(func() -> void: modulate = Color.WHITE)


func _tile_rect(tile: Vector2i) -> Rect2:
	return Rect2(BOARD_ORIGIN + Vector2(tile.x * TILE_PX, tile.y * TILE_PX), Vector2(TILE_PX, TILE_PX))
