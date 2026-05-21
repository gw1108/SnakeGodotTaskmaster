extends GdUnitTestSuite

const ArenaScript := preload("res://scripts/arena.gd")
const ARENA_SCENE_PATH := "res://scenes/Arena.tscn"


func test_default_grid_dimensions() -> void:
	var arena: Arena = auto_free(ArenaScript.new())
	assert_int(arena.grid_width).is_equal(20)
	assert_int(arena.grid_height).is_equal(15)
	assert_int(arena.cell_size).is_equal(32)


func test_is_wall_returns_true_for_corners() -> void:
	var arena: Arena = auto_free(ArenaScript.new())
	assert_bool(arena.is_wall(Vector2i(0, 0))).is_true()
	assert_bool(arena.is_wall(Vector2i(arena.grid_width - 1, 0))).is_true()
	assert_bool(arena.is_wall(Vector2i(0, arena.grid_height - 1))).is_true()
	assert_bool(arena.is_wall(Vector2i(arena.grid_width - 1, arena.grid_height - 1))).is_true()


func test_is_wall_returns_true_for_perimeter_edges() -> void:
	var arena: Arena = auto_free(ArenaScript.new())
	# Top and bottom rows
	assert_bool(arena.is_wall(Vector2i(5, 0))).is_true()
	assert_bool(arena.is_wall(Vector2i(5, arena.grid_height - 1))).is_true()
	# Left and right columns
	assert_bool(arena.is_wall(Vector2i(0, 5))).is_true()
	assert_bool(arena.is_wall(Vector2i(arena.grid_width - 1, 5))).is_true()


func test_is_wall_returns_false_for_interior() -> void:
	var arena: Arena = auto_free(ArenaScript.new())
	assert_bool(arena.is_wall(Vector2i(1, 1))).is_false()
	assert_bool(arena.is_wall(Vector2i(10, 7))).is_false()
	assert_bool(arena.is_wall(Vector2i(arena.grid_width - 2, arena.grid_height - 2))).is_false()


func test_is_wall_treats_out_of_bounds_as_wall() -> void:
	var arena: Arena = auto_free(ArenaScript.new())
	assert_bool(arena.is_wall(Vector2i(-1, 5))).is_true()
	assert_bool(arena.is_wall(Vector2i(5, -1))).is_true()
	assert_bool(arena.is_wall(Vector2i(arena.grid_width, 5))).is_true()
	assert_bool(arena.is_wall(Vector2i(5, arena.grid_height))).is_true()


func test_grid_to_world_returns_cell_center() -> void:
	var arena: Arena = auto_free(ArenaScript.new())
	# cell_size = 32 → cell (0,0) center is (16, 16)
	assert_that(arena.grid_to_world(Vector2i(0, 0))).is_equal(Vector2(16, 16))
	assert_that(arena.grid_to_world(Vector2i(1, 2))).is_equal(Vector2(48, 80))


func test_world_to_grid_floors_to_cell() -> void:
	var arena: Arena = auto_free(ArenaScript.new())
	assert_that(arena.world_to_grid(Vector2(0, 0))).is_equal(Vector2i(0, 0))
	assert_that(arena.world_to_grid(Vector2(31.9, 31.9))).is_equal(Vector2i(0, 0))
	assert_that(arena.world_to_grid(Vector2(32, 32))).is_equal(Vector2i(1, 1))
	assert_that(arena.world_to_grid(Vector2(48, 80))).is_equal(Vector2i(1, 2))


func test_grid_world_grid_round_trip() -> void:
	var arena: Arena = auto_free(ArenaScript.new())
	for pos in [Vector2i(0, 0), Vector2i(5, 7), Vector2i(19, 14)]:
		assert_that(arena.world_to_grid(arena.grid_to_world(pos))).is_equal(pos)


func test_ready_populates_tilemap_with_perimeter_walls() -> void:
	var arena: Arena = auto_free(load(ARENA_SCENE_PATH).instantiate())
	add_child(arena)
	var layer: TileMapLayer = arena.get_node("TileMapLayer")
	# Perimeter cells use the wall source
	assert_int(layer.get_cell_source_id(Vector2i(0, 0))).is_equal(Arena.WALL_SOURCE_ID)
	assert_int(layer.get_cell_source_id(Vector2i(arena.grid_width - 1, arena.grid_height - 1))) \
		.is_equal(Arena.WALL_SOURCE_ID)
	# Interior cells use the floor source
	assert_int(layer.get_cell_source_id(Vector2i(1, 1))).is_equal(Arena.FLOOR_SOURCE_ID)
	assert_int(layer.get_cell_source_id(Vector2i(10, 7))).is_equal(Arena.FLOOR_SOURCE_ID)


func test_ready_sets_tileset_cell_size() -> void:
	var arena: Arena = auto_free(load(ARENA_SCENE_PATH).instantiate())
	add_child(arena)
	var layer: TileMapLayer = arena.get_node("TileMapLayer")
	assert_that(layer.tile_set.tile_size).is_equal(Vector2i(arena.cell_size, arena.cell_size))
