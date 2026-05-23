class_name Arena
extends Node2D

const FLOOR_TILE_TEXTURE: Texture2D = preload("res://sprites/floor_tile.png")
const WALL_TILE_TEXTURE: Texture2D = preload("res://sprites/wall_tile.png")

const FLOOR_SOURCE_ID := 0
const WALL_SOURCE_ID := 1
const ATLAS_COORD := Vector2i.ZERO

@export var grid_width: int = 20
@export var grid_height: int = 15
@export var cell_size: int = 32

var _tile_map_layer: TileMapLayer


func _ready() -> void:
	_build_tilemap()
	_populate_tiles()


func is_wall(grid_pos: Vector2i) -> bool:
	if grid_pos.x <= 0 or grid_pos.y <= 0:
		return true
	if grid_pos.x >= grid_width - 1 or grid_pos.y >= grid_height - 1:
		return true
	return false


func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		(grid_pos.x + 0.5) * cell_size,
		(grid_pos.y + 0.5) * cell_size,
	)


func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / cell_size)),
		int(floor(world_pos.y / cell_size)),
	)


func _build_tilemap() -> void:
	_tile_map_layer = TileMapLayer.new()
	_tile_map_layer.name = "TileMapLayer"

	var ts := TileSet.new()
	ts.tile_size = Vector2i(cell_size, cell_size)
	ts.add_source(_make_atlas_source(FLOOR_TILE_TEXTURE), FLOOR_SOURCE_ID)
	ts.add_source(_make_atlas_source(WALL_TILE_TEXTURE), WALL_SOURCE_ID)

	_tile_map_layer.tile_set = ts
	add_child(_tile_map_layer)


func _make_atlas_source(texture: Texture2D) -> TileSetAtlasSource:
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(cell_size, cell_size)
	source.create_tile(ATLAS_COORD)
	return source


func _populate_tiles() -> void:
	for y in range(grid_height):
		for x in range(grid_width):
			var pos := Vector2i(x, y)
			var source_id := WALL_SOURCE_ID if is_wall(pos) else FLOOR_SOURCE_ID
			_tile_map_layer.set_cell(pos, source_id, ATLAS_COORD)
