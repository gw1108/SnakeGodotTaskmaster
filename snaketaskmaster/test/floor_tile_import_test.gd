extends GdUnitTestSuite

const FLOOR_TILE_PATH := "res://sprites/floor_tile.png"
const FLOOR_TILE_IMPORT_PATH := "res://sprites/floor_tile.png.import"

func test_floor_tile_texture_loads() -> void:
	var tex := load(FLOOR_TILE_PATH) as Texture2D
	assert_object(tex).is_not_null()
	assert_int(tex.get_width()).is_greater(0)
	assert_int(tex.get_height()).is_greater(0)

func test_floor_tile_import_uses_pixel_art_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(FLOOR_TILE_IMPORT_PATH)
	assert_int(err).is_equal(OK)
	# Lossless compression (0) keeps pixel art crisp.
	assert_that(cfg.get_value("params", "compress/mode")).is_equal(0)
	# Mipmaps off — pixel art renders at integer scales without filtering.
	assert_that(cfg.get_value("params", "mipmaps/generate")).is_equal(false)

func test_project_default_texture_filter_is_nearest() -> void:
	# 0 = Nearest neighbor (pixel art); see ProjectSettings docs.
	var filter: int = ProjectSettings.get_setting(
		"rendering/textures/canvas_textures/default_texture_filter", -1)
	assert_int(filter).is_equal(0)
