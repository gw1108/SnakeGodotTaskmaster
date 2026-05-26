class_name Food
extends Node2D
## Food model. Tracks the single piece of food as a grid cell and mirrors it
## onto one Sprite2D, matching the snake's rendering convention.

const FOOD_TEXTURE: Texture2D = preload("res://sprites/food.png")
const EAT_SOUND: AudioStream = preload("res://audio/eat_food.wav")

## Cell the food currently occupies; set by spawn().
var grid_pos: Vector2i = Vector2i(1, 1)

var sprite: Sprite2D
var audio_player: AudioStreamPlayer


func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = FOOD_TEXTURE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

	audio_player = AudioStreamPlayer.new()
	audio_player.stream = EAT_SOUND
	add_child(audio_player)


## Play the chomp sound; called by main when the snake eats this food.
func play_eat_sound() -> void:
	audio_player.play()


## Keep the sprite seated over the food's grid cell every frame.
func _process(_delta: float) -> void:
	sprite.position = _cell_to_world_center(grid_pos)


## grid_to_world() yields a cell's top-left; Sprite2D is centered, so nudge by
## half a cell to seat the sprite squarely over its grid tile.
func _cell_to_world_center(cell: Vector2i) -> Vector2:
	return Grid.grid_to_world(cell) + Vector2(Grid.CELL_SIZE, Grid.CELL_SIZE) * 0.5


## Pick a random interior cell (walls rim the perimeter) not covered by the
## snake body and move the food there. No-op if no empty cell exists.
func spawn(snake_body: Array[Vector2i]) -> void:
	var empty_cells: Array[Vector2i] = []
	for x in range(1, Grid.GRID_WIDTH - 1):
		for y in range(1, Grid.GRID_HEIGHT - 1):
			var cell := Vector2i(x, y)
			if cell not in snake_body:
				empty_cells.append(cell)
	if empty_cells.size() > 0:
		grid_pos = empty_cells.pick_random()
