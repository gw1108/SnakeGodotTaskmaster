extends Node2D

const FLOOR_TEXTURE: Texture2D = preload("res://assets/sprites/floor_tile.png")
const WALL_TEXTURE: Texture2D = preload("res://assets/sprites/wall_tile.png")

@onready var floor_layer: TileMapLayer = $FloorLayer
@onready var wall_layer: TileMapLayer = $WallLayer

func _ready() -> void:
	_setup_tileset(floor_layer, FLOOR_TEXTURE)
	_setup_tileset(wall_layer, WALL_TEXTURE)
	_populate_floor()
	_populate_walls()

func _setup_tileset(layer: TileMapLayer, texture: Texture2D) -> void:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(GameConstants.CELL_SIZE, GameConstants.CELL_SIZE)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(GameConstants.CELL_SIZE, GameConstants.CELL_SIZE)
	atlas.create_tile(Vector2i(0, 0))
	tileset.add_source(atlas, 0)
	layer.tile_set = tileset

func _populate_floor() -> void:
	for x in range(GameConstants.GRID_WIDTH):
		for y in range(GameConstants.GRID_HEIGHT):
			floor_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))

func _populate_walls() -> void:
	var w: int = GameConstants.GRID_WIDTH
	var h: int = GameConstants.GRID_HEIGHT
	for x in range(-1, w + 1):
		wall_layer.set_cell(Vector2i(x, -1), 0, Vector2i(0, 0))
		wall_layer.set_cell(Vector2i(x, h), 0, Vector2i(0, 0))
	for y in range(0, h):
		wall_layer.set_cell(Vector2i(-1, y), 0, Vector2i(0, 0))
		wall_layer.set_cell(Vector2i(w, y), 0, Vector2i(0, 0))
