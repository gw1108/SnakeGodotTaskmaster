extends GdUnitTestSuite

const PLAYER_BODY_PATH := "res://sprites/player_body.png"
const PLAYER_BODY_IMPORT_PATH := "res://sprites/player_body.png.import"

func test_player_body_texture_loads() -> void:
	var tex := load(PLAYER_BODY_PATH) as Texture2D
	assert_object(tex).is_not_null()
	assert_int(tex.get_width()).is_greater(0)
	assert_int(tex.get_height()).is_greater(0)

func test_player_body_import_uses_pixel_art_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(PLAYER_BODY_IMPORT_PATH)
	assert_int(err).is_equal(OK)
	# Lossless compression (0) keeps pixel art crisp.
	assert_that(cfg.get_value("params", "compress/mode")).is_equal(0)
	# Mipmaps off — pixel art renders at integer scales without filtering.
	assert_that(cfg.get_value("params", "mipmaps/generate")).is_equal(false)

func test_player_body_matches_tile_dimensions() -> void:
	var body := load(PLAYER_BODY_PATH) as Texture2D
	var floor_tex := load("res://sprites/floor_tile.png") as Texture2D
	assert_int(body.get_width()).is_equal(floor_tex.get_width())
	assert_int(body.get_height()).is_equal(floor_tex.get_height())
