extends GdUnitTestSuite

# Golden path integration test: walks the full game session a player experiences
# — start → steer → eat & grow → wall collision → game over → restart — through a
# live Main.tscn instance. Unlike game_controller_test (which exercises pieces in
# isolation), this drives them in sequence so the core loop is verified end to end.
#
# The scene is instantiated and added to the tree so _ready() builds the snake,
# timer, labels, and visuals. Steps advance the game by calling _on_tick()
# directly (synchronous, no waiting on the real timer) and steer/restart via real
# Input actions, the same path _process() uses in play.

const MainScene := preload("res://Main.tscn")

# Input actions are global engine state; release them after the test so a
# simulated press can't leak elsewhere.
func after_test() -> void:
	for action in ["move_up", "move_down", "move_left", "move_right"]:
		Input.action_release(action)

func test_golden_path_full_game_cycle() -> void:
	var controller: GameController = auto_free(MainScene.instantiate())
	add_child(controller)

	# --- Start: fresh 3-segment snake, zero score, playing, score shown. ---
	assert_int(controller.snake.body.size()).is_equal(3)
	assert_int(controller.score).is_equal(0)
	assert_int(controller.state).is_equal(GameController.GameState.PLAYING)
	assert_bool(controller.score_label.visible).is_true()
	assert_bool(controller.game_over_label.visible).is_false()

	# --- Steer: hold UP, poll input; the snake turns from its spawn RIGHT to UP. ---
	Input.action_press("move_up")
	controller._process(0.0)
	assert_that(controller.snake.direction).is_equal(Vector2i.UP)
	Input.action_release("move_up")

	# --- Eat: food directly ahead -> snake grows and score rises. Do it twice. ---
	for expected_score in [1, 2]:
		controller.food_position = controller.snake.get_head() + controller.snake.direction
		var len_before := controller.snake.body.size()
		controller._on_tick()
		assert_int(controller.snake.body.size()).is_equal(len_before + 1)
		assert_int(controller.score).is_equal(expected_score)
		assert_int(controller.state).is_equal(GameController.GameState.PLAYING)
	assert_str(controller.score_label.text).is_equal("Score: 2")

	# --- Collide: head one cell inside the right border, moving into it. The next
	# tick lands on the border and ends the game; the run becomes the high score. ---
	var head := Vector2i(Grid.GRID_WIDTH - 2, 5)
	controller.snake.body = [head, head - Vector2i.RIGHT, head - Vector2i.RIGHT * 2]
	controller.snake.direction = Vector2i.RIGHT
	controller.food_position = Vector2i(1, 1)  # well clear of the head's path
	controller._on_tick()
	assert_int(controller.state).is_equal(GameController.GameState.GAME_OVER)
	assert_bool(controller.tick_timer.is_stopped()).is_true()
	assert_int(controller.high_score).is_equal(2)
	assert_bool(controller.score_label.visible).is_false()
	assert_bool(controller.game_over_label.visible).is_true()

	# --- Restart: any key press while game over starts a fresh game. ---
	Input.action_press("move_up")
	controller._process(0.0)
	assert_int(controller.state).is_equal(GameController.GameState.PLAYING)
	assert_int(controller.score).is_equal(0)
	assert_int(controller.snake.body.size()).is_equal(3)
	assert_bool(controller.score_label.visible).is_true()
	assert_bool(controller.game_over_label.visible).is_false()
	# High score persists across the restart.
	assert_int(controller.high_score).is_equal(2)
