extends GdUnitTestSuite

## Golden-path integration test: instantiates the real wired Main.tscn and drives
## the Game node through the loop a player typically performs — title -> start ->
## move -> steer -> eat/grow -> die -> game over -> restart. Ticks are driven
## manually (Timer stopped) for determinism; _unhandled_input is dead headless,
## so input is injected via the InputBuffer directly.

const GameScript := preload("res://scripts/game.gd")
const MainScene := preload("res://Main.tscn")
const GameStateScript := preload("res://scripts/game_state.gd")

var _game: Node2D


func before_test() -> void:
	_game = auto_free(MainScene.instantiate())
	add_child(_game)   # triggers Game._ready (FSM=TITLE, timer connected)
	_game._timer.stop()   # drive ticks manually


func test_golden_path_full_game_loop() -> void:
	# Boots into TITLE.
	assert_int(_game._current_mode).is_equal(GameScript.GameMode.TITLE)

	# Confirm starts a fresh run.
	_game._on_confirm()
	_game._timer.stop()
	assert_int(_game._current_mode).is_equal(GameScript.GameMode.PLAYING)
	var state: GameState = _game._state
	assert_array(state.snake).has_size(GameScript.START_LENGTH)
	assert_vector(state.direction).is_equal(Vector2i.RIGHT)
	assert_bool(state.apple != GameStateScript.NO_APPLE).is_true()

	# A plain tick moves the head right and preserves length (no apple ahead).
	state.apple = GameStateScript.NO_APPLE
	var head_before: Vector2i = state.snake[0]
	_game._on_tick()
	assert_vector(state.snake[0]).is_equal(head_before + Vector2i.RIGHT)
	assert_array(state.snake).has_size(GameScript.START_LENGTH)

	# Steering: a buffered UP turn commits on the next tick.
	_game._input_buffer.push(Vector2i.UP)
	_game._on_tick()
	assert_vector(state.direction).is_equal(Vector2i.UP)

	# Eating: apple placed directly ahead -> score +1, grow, new apple spawned.
	var score_before: int = state.score
	var len_before: int = state.snake.size()
	state.apple = state.snake[0] + Vector2i.UP
	_game._on_tick()
	assert_int(state.score).is_equal(score_before + 1)
	assert_array(state.snake).has_size(len_before + 1)
	assert_bool(state.apple != GameStateScript.NO_APPLE).is_true()

	# Death: send the head into the top wall. Keep best high so no save fires.
	_game._best_score = 9999
	state.snake[0] = Vector2i(state.snake[0].x, 0)
	state.direction = Vector2i.UP
	_game._input_buffer.clear()
	_game._on_tick()
	assert_int(_game._current_mode).is_equal(GameScript.GameMode.GAME_OVER)
	assert_bool(state.alive).is_false()
	assert_bool(_game._timer.is_stopped()).is_true()

	# Restart from GAME_OVER returns to a fresh PLAYING run.
	_game._on_confirm()
	_game._timer.stop()
	assert_int(_game._current_mode).is_equal(GameScript.GameMode.PLAYING)
	assert_array(_game._state.snake).has_size(GameScript.START_LENGTH)
	assert_int(_game._state.score).is_equal(0)
	assert_bool(_game._state.alive).is_true()


func test_pause_toggles_playing_and_stops_clock() -> void:
	_game._on_confirm()   # TITLE -> PLAYING
	assert_int(_game._current_mode).is_equal(GameScript.GameMode.PLAYING)

	_game._on_pause()     # PLAYING -> PAUSED
	assert_int(_game._current_mode).is_equal(GameScript.GameMode.PAUSED)
	assert_bool(_game._timer.is_stopped()).is_true()

	_game._on_pause()     # PAUSED -> PLAYING (clock resumes)
	assert_int(_game._current_mode).is_equal(GameScript.GameMode.PLAYING)
	assert_bool(_game._timer.is_stopped()).is_false()
	_game._timer.stop()


func test_new_best_persists_through_score_store() -> void:
	# ScoreStore round-trips the best score; original value restored afterward.
	var original := ScoreStore.load_best()
	var high := original + 1000
	ScoreStore.save_best(high)
	assert_int(ScoreStore.load_best()).is_equal(high)
	ScoreStore.save_best(original)
	assert_int(ScoreStore.load_best()).is_equal(original)
