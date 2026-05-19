extends GdUnitTestSuite

const PLAYFIELD_SCENE_PATH := "res://scenes/playfield.tscn"
const FLOOR_SOURCE_ID := 0
const WALL_SOURCE_ID := 1


func _instantiate_playfield() -> Node2D:
	var packed := load(PLAYFIELD_SCENE_PATH) as PackedScene
	var pf: Node2D = auto_free(packed.instantiate())
	add_child(pf)
	return pf


func test_scene_file_exists() -> void:
	assert_file(PLAYFIELD_SCENE_PATH).exists()


func test_playfield_has_tilemap_child() -> void:
	var pf := _instantiate_playfield()
	var tilemap := pf.get_node_or_null("TileMapLayer")
	assert_object(tilemap).is_not_null()
	assert_object(tilemap).is_instanceof(TileMapLayer)


func test_tileset_has_two_atlas_sources_with_correct_size() -> void:
	var pf := _instantiate_playfield()
	var tilemap: TileMapLayer = pf.get_node("TileMapLayer")
	var ts := tilemap.tile_set
	assert_object(ts).is_not_null()
	assert_that(ts.tile_size).is_equal(Vector2i(Grid.CELL_SIZE, Grid.CELL_SIZE))
	var floor_src := ts.get_source(FLOOR_SOURCE_ID) as TileSetAtlasSource
	var wall_src := ts.get_source(WALL_SOURCE_ID) as TileSetAtlasSource
	assert_object(floor_src).is_not_null()
	assert_object(wall_src).is_not_null()
	assert_object(floor_src.texture).is_not_null()
	assert_object(wall_src.texture).is_not_null()
	assert_bool(floor_src.has_tile(Vector2i(0, 0))).is_true()
	assert_bool(wall_src.has_tile(Vector2i(0, 0))).is_true()


func test_full_grid_is_painted() -> void:
	var pf := _instantiate_playfield()
	var tilemap: TileMapLayer = pf.get_node("TileMapLayer")
	var used := tilemap.get_used_cells()
	var expected_count := (Grid.GRID_WIDTH + 2) * (Grid.GRID_HEIGHT + 2)
	assert_int(used.size()).is_equal(expected_count)


func test_border_cells_use_wall_source_and_interior_uses_floor() -> void:
	var pf := _instantiate_playfield()
	var tilemap: TileMapLayer = pf.get_node("TileMapLayer")
	var wall_cells := 0
	var floor_cells := 0
	for x in range(Grid.GRID_WIDTH + 2):
		for y in range(Grid.GRID_HEIGHT + 2):
			var cell := Vector2i(x, y)
			var src_id := tilemap.get_cell_source_id(cell)
			if Grid.is_wall(cell):
				assert_int(src_id).is_equal(WALL_SOURCE_ID)
				wall_cells += 1
			else:
				assert_int(src_id).is_equal(FLOOR_SOURCE_ID)
				floor_cells += 1
	# Border = total - interior; interior = GRID_WIDTH * GRID_HEIGHT
	var expected_floor := Grid.GRID_WIDTH * Grid.GRID_HEIGHT
	var expected_wall := (Grid.GRID_WIDTH + 2) * (Grid.GRID_HEIGHT + 2) - expected_floor
	assert_int(floor_cells).is_equal(expected_floor)
	assert_int(wall_cells).is_equal(expected_wall)


func test_all_painted_cells_use_atlas_origin() -> void:
	var pf := _instantiate_playfield()
	var tilemap: TileMapLayer = pf.get_node("TileMapLayer")
	for cell in tilemap.get_used_cells():
		assert_that(tilemap.get_cell_atlas_coords(cell)).is_equal(Vector2i(0, 0))


func test_game_scene_uses_playfield_instance() -> void:
	var packed := load("res://scenes/game.tscn") as PackedScene
	var game: Node2D = auto_free(packed.instantiate())
	add_child(game)
	var playfield := game.get_node_or_null("Playfield")
	assert_object(playfield).is_not_null()
	# Playfield script should be wired
	assert_object(playfield.get_script()).is_not_null()
	var tilemap := playfield.get_node_or_null("TileMapLayer")
	assert_object(tilemap).is_not_null()
	# After _ready, full grid is painted
	var used := (tilemap as TileMapLayer).get_used_cells()
	assert_int(used.size()).is_equal((Grid.GRID_WIDTH + 2) * (Grid.GRID_HEIGHT + 2))
