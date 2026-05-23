extends GdUnitTestSuite

const WALL_TILE_PATH := "res://sprites/wall_tile.png"
const WALL_TILE_IMPORT_PATH := "res://sprites/wall_tile.png.import"

func test_wall_tile_texture_loads() -> void:
	var tex := load(WALL_TILE_PATH) as Texture2D
	assert_object(tex).is_not_null()
	assert_int(tex.get_width()).is_greater(0)
	assert_int(tex.get_height()).is_greater(0)

func test_wall_tile_import_uses_pixel_art_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(WALL_TILE_IMPORT_PATH)
	assert_int(err).is_equal(OK)
	# Lossless compression (0) keeps pixel art crisp.
	assert_that(cfg.get_value("params", "compress/mode")).is_equal(0)
	# Mipmaps off — pixel art renders at integer scales without filtering.
	assert_that(cfg.get_value("params", "mipmaps/generate")).is_equal(false)

func test_wall_tile_matches_floor_tile_dimensions() -> void:
	var wall := load(WALL_TILE_PATH) as Texture2D
	var floor := load("res://sprites/floor_tile.png") as Texture2D
	assert_int(wall.get_width()).is_equal(floor.get_width())
	assert_int(wall.get_height()).is_equal(floor.get_height())
