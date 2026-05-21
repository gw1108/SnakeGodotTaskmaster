extends GdUnitTestSuite

const FOOD_PATH := "res://sprites/food.png"
const FOOD_IMPORT_PATH := "res://sprites/food.png.import"

func test_food_texture_loads() -> void:
	var tex := load(FOOD_PATH) as Texture2D
	assert_object(tex).is_not_null()
	assert_int(tex.get_width()).is_greater(0)
	assert_int(tex.get_height()).is_greater(0)

func test_food_import_uses_pixel_art_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(FOOD_IMPORT_PATH)
	assert_int(err).is_equal(OK)
	assert_that(cfg.get_value("params", "compress/mode")).is_equal(0)
	assert_that(cfg.get_value("params", "mipmaps/generate")).is_equal(false)

func test_food_matches_tile_dimensions() -> void:
	var food := load(FOOD_PATH) as Texture2D
	var floor_tex := load("res://sprites/floor_tile.png") as Texture2D
	assert_int(food.get_width()).is_equal(floor_tex.get_width())
	assert_int(food.get_height()).is_equal(floor_tex.get_height())
