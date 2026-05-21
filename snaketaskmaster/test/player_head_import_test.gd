extends GdUnitTestSuite

const PLAYER_HEAD_PATH := "res://sprites/player_head.png"
const PLAYER_HEAD_IMPORT_PATH := "res://sprites/player_head.png.import"

func test_player_head_texture_loads() -> void:
	var tex := load(PLAYER_HEAD_PATH) as Texture2D
	assert_object(tex).is_not_null()
	assert_int(tex.get_width()).is_greater(0)
	assert_int(tex.get_height()).is_greater(0)

func test_player_head_import_uses_pixel_art_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(PLAYER_HEAD_IMPORT_PATH)
	assert_int(err).is_equal(OK)
	# Lossless compression (0) keeps pixel art crisp.
	assert_that(cfg.get_value("params", "compress/mode")).is_equal(0)
	# Mipmaps off — pixel art renders at integer scales without filtering.
	assert_that(cfg.get_value("params", "mipmaps/generate")).is_equal(false)

func test_player_head_matches_tile_dimensions() -> void:
	var head := load(PLAYER_HEAD_PATH) as Texture2D
	var floor_tex := load("res://sprites/floor_tile.png") as Texture2D
	assert_int(head.get_width()).is_equal(floor_tex.get_width())
	assert_int(head.get_height()).is_equal(floor_tex.get_height())
