extends Node2D

const FLOOR_TEXTURE_PATH := "res://source/sprites/floor_tile.png"
const WALL_TEXTURE_PATH := "res://source/sprites/wall_tile.png"
const FLOOR_SOURCE_ID := 0
const WALL_SOURCE_ID := 1
const ATLAS_COORD := Vector2i(0, 0)

@onready var tilemap: TileMapLayer = $TileMapLayer


func _ready() -> void:
	tilemap.tile_set = _build_tileset()
	_paint_grid()


func _build_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(Grid.CELL_SIZE, Grid.CELL_SIZE)
	ts.add_source(_make_atlas_source(FLOOR_TEXTURE_PATH), FLOOR_SOURCE_ID)
	ts.add_source(_make_atlas_source(WALL_TEXTURE_PATH), WALL_SOURCE_ID)
	return ts


func _make_atlas_source(texture_path: String) -> TileSetAtlasSource:
	var src := TileSetAtlasSource.new()
	src.texture = load(texture_path)
	src.texture_region_size = Vector2i(Grid.CELL_SIZE, Grid.CELL_SIZE)
	src.create_tile(ATLAS_COORD)
	return src


func _paint_grid() -> void:
	for x in range(Grid.GRID_WIDTH + 2):
		for y in range(Grid.GRID_HEIGHT + 2):
			var cell := Vector2i(x, y)
			var source_id := WALL_SOURCE_ID if Grid.is_wall(cell) else FLOOR_SOURCE_ID
			tilemap.set_cell(cell, source_id, ATLAS_COORD)
