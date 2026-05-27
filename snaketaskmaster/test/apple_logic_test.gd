extends GdUnitTestSuite

const AppleLogicScript := preload("res://scripts/apple_logic.gd")
const GameStateScript := preload("res://scripts/game_state.gd")


func _state(bounds: Vector2i, snake: Array[Vector2i]) -> GameState:
	var s := GameStateScript.new()
	s.bounds = bounds
	s.snake = snake
	s.apple = GameStateScript.NO_APPLE
	return s


func _seeded_rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_spawn_places_apple_on_free_tile() -> void:
	var s := _state(Vector2i(5, 5), [Vector2i(2, 2)] as Array[Vector2i])
	var tile := AppleLogicScript.spawn(s, _seeded_rng(123))
	# Inside bounds and not on the snake.
	assert_bool(tile.x >= 0 and tile.x < 5 and tile.y >= 0 and tile.y < 5).is_true()
	assert_bool(s.snake.has(tile)).is_false()
	assert_vector(s.apple).is_equal(tile)


func test_spawn_is_deterministic_for_a_given_seed() -> void:
	var a := _state(Vector2i(10, 10), [Vector2i(0, 0), Vector2i(1, 0)] as Array[Vector2i])
	var b := _state(Vector2i(10, 10), [Vector2i(0, 0), Vector2i(1, 0)] as Array[Vector2i])
	var tile_a := AppleLogicScript.spawn(a, _seeded_rng(42))
	var tile_b := AppleLogicScript.spawn(b, _seeded_rng(42))
	assert_vector(tile_a).is_equal(tile_b)


func test_spawn_never_lands_on_snake_when_one_tile_free() -> void:
	# Fill a 2x2 board except (1,1); spawn must pick exactly (1,1).
	var snake := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)] as Array[Vector2i]
	var s := _state(Vector2i(2, 2), snake)
	var tile := AppleLogicScript.spawn(s, _seeded_rng(7))
	assert_vector(tile).is_equal(Vector2i(1, 1))
	assert_vector(s.apple).is_equal(Vector2i(1, 1))


func test_spawn_returns_sentinel_when_board_full() -> void:
	var snake := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)] as Array[Vector2i]
	var s := _state(Vector2i(2, 2), snake)
	var tile := AppleLogicScript.spawn(s, _seeded_rng(7))
	assert_vector(tile).is_equal(GameStateScript.NO_APPLE)
	assert_vector(s.apple).is_equal(GameStateScript.NO_APPLE)
