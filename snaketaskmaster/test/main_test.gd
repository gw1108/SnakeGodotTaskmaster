extends GdUnitTestSuite

# main.gd has no class_name, so its GameState enum can't be named here.
# game_state is stored as an int: PLAYING == 0, GAME_OVER == 1.
const PLAYING: int = 0
const GAME_OVER: int = 1


# Instantiate the full Main scene so $TickTimer, $DeathSound, snake and food
# all exist exactly as they do at runtime. auto_free reaps the tree afterward.
func _make_main():
	var main = auto_free(load("res://Main.tscn").instantiate())
	add_child(main)
	return main


# main.snake is reached through an untyped ref, so an untyped Array literal
# won't coerce into the snake's Array[Vector2i] body. Build the typed array here.
func _set_body(main, cells: Array[Vector2i], dir: Vector2i) -> void:
	main.snake.body = cells
	main.snake.direction = dir


func test_wall_collision_triggers_game_over() -> void:
	var main = _make_main()
	# Head sits on the right edge; one move RIGHT steps off the grid.
	var body: Array[Vector2i] = [
		Vector2i(Grid.GRID_WIDTH - 1, 7),
		Vector2i(Grid.GRID_WIDTH - 2, 7),
		Vector2i(Grid.GRID_WIDTH - 3, 7),
	]
	_set_body(main, body, Vector2i.RIGHT)
	main._on_tick()
	assert_int(main.game_state).is_equal(GAME_OVER)


func test_self_collision_triggers_game_over() -> void:
	var main = _make_main()
	# A looped body where moving DOWN folds the head onto a non-tail cell.
	var body: Array[Vector2i] = [
		Vector2i(5, 5), Vector2i(5, 6), Vector2i(5, 7),
		Vector2i(6, 7), Vector2i(6, 6), Vector2i(6, 5),
	]
	_set_body(main, body, Vector2i.DOWN)
	main._on_tick()
	assert_int(main.game_state).is_equal(GAME_OVER)


func test_clear_move_stays_playing() -> void:
	var main = _make_main()
	# Open interior with room ahead: no wall or self hit this tick.
	var body: Array[Vector2i] = [Vector2i(5, 5), Vector2i(4, 5), Vector2i(3, 5)]
	_set_body(main, body, Vector2i.RIGHT)
	main._on_tick()
	assert_int(main.game_state).is_equal(PLAYING)


func test_game_over_stops_tick_timer() -> void:
	var main = _make_main()
	var body: Array[Vector2i] = [
		Vector2i(Grid.GRID_WIDTH - 1, 7),
		Vector2i(Grid.GRID_WIDTH - 2, 7),
		Vector2i(Grid.GRID_WIDTH - 3, 7),
	]
	_set_body(main, body, Vector2i.RIGHT)
	main._on_tick()
	assert_bool(main.get_node("TickTimer").is_stopped()).is_true()


func test_tick_is_ignored_after_game_over() -> void:
	var main = _make_main()
	main.game_state = GAME_OVER
	# Place the head somewhere a move would normally advance it.
	var body: Array[Vector2i] = [Vector2i(5, 5), Vector2i(4, 5), Vector2i(3, 5)]
	_set_body(main, body, Vector2i.RIGHT)
	main._on_tick()
	# Frozen: move() never ran, so the head is unchanged.
	assert_that(main.snake.get_head()).is_equal(Vector2i(5, 5))


func test_game_over_shows_panel() -> void:
	var main = _make_main()
	main._game_over()
	assert_bool(main.get_node("HUD/GameOverPanel").visible).is_true()


func test_restart_resets_score() -> void:
	var main = _make_main()
	main.score = 7
	main._game_over()
	main._restart_game()
	assert_int(main.score).is_equal(0)


func test_restart_resets_state_to_playing() -> void:
	var main = _make_main()
	main._game_over()
	main._restart_game()
	assert_int(main.game_state).is_equal(PLAYING)


func test_restart_hides_panel() -> void:
	var main = _make_main()
	main._game_over()
	main._restart_game()
	assert_bool(main.get_node("HUD/GameOverPanel").visible).is_false()


func test_restart_restarts_tick_timer() -> void:
	var main = _make_main()
	main._game_over()
	main._restart_game()
	assert_bool(main.get_node("TickTimer").is_stopped()).is_false()


func test_restart_rebuilds_snake_at_start() -> void:
	var main = _make_main()
	# Grow and reposition the snake, then confirm restart rebuilds the original.
	var body: Array[Vector2i] = [Vector2i(5, 5), Vector2i(5, 6), Vector2i(5, 7), Vector2i(5, 8)]
	_set_body(main, body, Vector2i.UP)
	main._game_over()
	main._restart_game()
	assert_int(main.snake.body.size()).is_equal(3)
	assert_that(main.snake.get_head()).is_equal(Vector2i(10, 7))
