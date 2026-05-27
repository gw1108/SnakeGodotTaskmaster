extends GdUnitTestSuite

const GameStateScript := preload("res://scripts/game_state.gd")

const BOUNDS := Vector2i(25, 25)
const START_LENGTH := 3


func test_new_game_initializes_default_run_state() -> void:
	var state: GameState = GameStateScript.new_game(BOUNDS, START_LENGTH)
	assert_vector(state.bounds).is_equal(BOUNDS)
	assert_vector(state.direction).is_equal(Vector2i.RIGHT)
	assert_vector(state.apple).is_equal(GameStateScript.NO_APPLE)
	assert_int(state.grow_pending).is_equal(0)
	assert_int(state.score).is_equal(0)
	assert_bool(state.alive).is_true()


func test_new_game_builds_snake_heading_right_with_head_at_index_0() -> void:
	var state: GameState = GameStateScript.new_game(BOUNDS, START_LENGTH)
	# Center of a 25x25 board is (12, 12); body extends left so it heads Right.
	assert_array(state.snake).has_size(START_LENGTH)
	assert_vector(state.snake[0]).is_equal(Vector2i(12, 12))
	assert_vector(state.snake[1]).is_equal(Vector2i(11, 12))
	assert_vector(state.snake[2]).is_equal(Vector2i(10, 12))


func test_reset_restores_start_state_in_place() -> void:
	var state: GameState = GameStateScript.new_game(BOUNDS, START_LENGTH)
	# Dirty the state as if mid-run.
	state.score = 7
	state.grow_pending = 2
	state.alive = false
	state.direction = Vector2i.UP
	state.apple = Vector2i(3, 4)
	state.snake = [Vector2i(0, 0)]

	state.reset(BOUNDS, START_LENGTH)

	assert_int(state.score).is_equal(0)
	assert_int(state.grow_pending).is_equal(0)
	assert_bool(state.alive).is_true()
	assert_vector(state.direction).is_equal(Vector2i.RIGHT)
	assert_vector(state.apple).is_equal(GameStateScript.NO_APPLE)
	assert_array(state.snake).has_size(START_LENGTH)
	assert_vector(state.snake[0]).is_equal(Vector2i(12, 12))


func test_reset_respects_custom_bounds_and_length() -> void:
	var state: GameState = GameStateScript.new_game(BOUNDS, START_LENGTH)
	state.reset(Vector2i(10, 8), 2)
	assert_vector(state.bounds).is_equal(Vector2i(10, 8))
	assert_array(state.snake).has_size(2)
	# Center of (10, 8) is (5, 4).
	assert_vector(state.snake[0]).is_equal(Vector2i(5, 4))
	assert_vector(state.snake[1]).is_equal(Vector2i(4, 4))
