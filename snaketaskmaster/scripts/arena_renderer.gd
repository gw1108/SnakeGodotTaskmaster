extends Node2D
class_name ArenaRenderer
## Renders the static arena background: a wall tile on every border cell and a
## floor tile on every interior cell.
##
## The layout never changes during play, so the tiles are built once (in _ready,
## or via build() from a test) as plain Sprite2D children. This node sits at the
## back of Main.tscn so the snake and food draw on top of it.

const FLOOR_TEXTURE: Texture2D = preload("res://source/sprites/floor_tile.png")
const WALL_TEXTURE: Texture2D = preload("res://source/sprites/wall_tile.png")

func _ready() -> void:
	build()

## Instantiates one Sprite2D per grid cell at the cell's top-left pixel corner.
## Border cells get the wall texture, interior cells the floor texture. Sprites
## are left-anchored (centered = false) so the texture aligns with cell_to_pixel().
## Clears any existing tiles first so a rebuild doesn't stack duplicates.
func build() -> void:
	for child in get_children():
		child.queue_free()
	for x in Grid.GRID_WIDTH:
		for y in Grid.GRID_HEIGHT:
			var cell := Vector2i(x, y)
			var sprite := Sprite2D.new()
			sprite.centered = false
			sprite.texture = WALL_TEXTURE if Grid.is_border_cell(cell) else FLOOR_TEXTURE
			sprite.position = Grid.cell_to_pixel(cell)
			add_child(sprite)
