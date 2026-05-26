extends GdUnitTestSuite

# GameController is a global `class_name` class, referenced directly. The
# controller is added to the tree so _ready() runs (creates timer + snake);
# tests are synchronous so the timer never fires on its own.

func _make_controller() -> GameController:
	var controller: GameController = auto_free(GameController.new())
	add_child(controller)
	return controller

# Input actions are global engine state; release them after every test so a
# simulated press can't leak into the next one.
func after_test() -> void:
	for action in ["move_up", "move_down", "move_left", "move_right"]:
		Input.action_release(action)

func test_ready_initializes_snake_and_timer() -> void:
	var controller := _make_controller()
	assert_object(controller.snake).is_not_null()
	assert_object(controller.tick_timer).is_not_null()
	assert_float(controller.tick_timer.wait_time).is_equal(GameController.TICK_INTERVAL)
	assert_bool(controller.tick_timer.one_shot).is_false()

func test_ready_starts_in_playing_state_with_zero_score() -> void:
	var controller := _make_controller()
	assert_int(controller.state).is_equal(GameController.GameState.PLAYING)
	assert_int(controller.score).is_equal(0)

func test_on_tick_moves_snake_forward() -> void:
	var controller := _make_controller()
	var old_head: Vector2i = controller.snake.get_head()
	controller._on_tick()
	assert_that(controller.snake.get_head()).is_equal(old_head + controller.snake.direction)

func test_on_tick_ignored_when_game_over() -> void:
	var controller := _make_controller()
	controller.state = GameController.GameState.GAME_OVER
	var head_before: Vector2i = controller.snake.get_head()
	controller._on_tick()
	assert_that(controller.snake.get_head()).is_equal(head_before)

func test_game_over_sets_state_and_stops_timer() -> void:
	var controller := _make_controller()
	controller.game_over()
	assert_int(controller.state).is_equal(GameController.GameState.GAME_OVER)
	assert_bool(controller.tick_timer.is_stopped()).is_true()

func test_game_over_updates_high_score_when_score_higher() -> void:
	var controller := _make_controller()
	controller.score = 7
	controller.game_over()
	assert_int(controller.high_score).is_equal(7)

func test_game_over_keeps_high_score_when_score_lower() -> void:
	var controller := _make_controller()
	controller.high_score = 10
	controller.score = 4
	controller.game_over()
	assert_int(controller.high_score).is_equal(10)

func test_reset_game_zeroes_score_and_returns_to_playing() -> void:
	var controller := _make_controller()
	controller.score = 5
	controller.game_over()
	controller.reset_game()
	assert_int(controller.score).is_equal(0)
	assert_int(controller.state).is_equal(GameController.GameState.PLAYING)
	assert_bool(controller.tick_timer.is_stopped()).is_false()

func test_reset_game_creates_fresh_snake() -> void:
	var controller := _make_controller()
	controller._on_tick()
	var moved_snake := controller.snake
	controller.reset_game()
	# A new Snake instance, spawned back at its 3-segment starting layout.
	assert_object(controller.snake).is_not_same(moved_snake)
	assert_array(controller.snake.body).has_size(3)

func test_process_steers_snake_to_held_direction() -> void:
	var controller := _make_controller()
	# Snake spawns facing RIGHT; UP is a valid 90-degree turn.
	Input.action_press("move_up")
	controller._process(0.0)
	assert_that(controller.snake.direction).is_equal(Vector2i.UP)

func test_process_rejects_180_reversal() -> void:
	var controller := _make_controller()
	# Facing RIGHT with 3 segments: LEFT is a reversal and must be ignored.
	Input.action_press("move_left")
	controller._process(0.0)
	assert_that(controller.snake.direction).is_equal(Vector2i.RIGHT)

func test_process_leaves_direction_unchanged_with_no_input() -> void:
	var controller := _make_controller()
	controller._process(0.0)
	assert_that(controller.snake.direction).is_equal(Vector2i.RIGHT)

func test_process_restarts_on_input_when_game_over() -> void:
	var controller := _make_controller()
	controller.game_over()
	Input.action_press("move_up")
	controller._process(0.0)
	assert_int(controller.state).is_equal(GameController.GameState.PLAYING)

func test_process_stays_game_over_without_input() -> void:
	var controller := _make_controller()
	controller.game_over()
	controller._process(0.0)
	assert_int(controller.state).is_equal(GameController.GameState.GAME_OVER)

func test_ready_spawns_food_on_valid_interior_cell() -> void:
	var controller := _make_controller()
	assert_bool(Grid.is_valid_cell(controller.food_position)).is_true()
	assert_bool(Grid.is_border_cell(controller.food_position)).is_false()

func test_spawn_food_never_lands_on_border_or_snake() -> void:
	var controller := _make_controller()
	# Many draws: every result must be a non-border interior cell off the snake.
	for _i in range(200):
		controller.spawn_food()
		assert_bool(Grid.is_border_cell(controller.food_position)).is_false()
		assert_bool(controller.snake.body.has(controller.food_position)).is_false()

func test_spawn_food_no_op_when_interior_full() -> void:
	var controller := _make_controller()
	# Fill every interior cell so there is nowhere new to place food. spawn_food
	# must leave the existing food_position untouched rather than clearing it.
	var full: Array[Vector2i] = []
	for x in range(1, Grid.GRID_WIDTH - 1):
		for y in range(1, Grid.GRID_HEIGHT - 1):
			full.append(Vector2i(x, y))
	controller.snake.body = full
	var sentinel := Vector2i(3, 4)
	controller.food_position = sentinel
	controller.spawn_food()
	assert_that(controller.food_position).is_equal(sentinel)

func test_poll_direction_returns_each_held_direction() -> void:
	var controller := _make_controller()
	Input.action_press("move_down")
	assert_that(controller._poll_direction()).is_equal(Vector2i.DOWN)
	Input.action_release("move_down")
	Input.action_press("move_left")
	assert_that(controller._poll_direction()).is_equal(Vector2i.LEFT)
	Input.action_release("move_left")
	Input.action_press("move_right")
	assert_that(controller._poll_direction()).is_equal(Vector2i.RIGHT)

func test_poll_direction_returns_zero_with_no_input() -> void:
	var controller := _make_controller()
	assert_that(controller._poll_direction()).is_equal(Vector2i.ZERO)

func test_poll_direction_resolves_simultaneous_presses_by_priority() -> void:
	var controller := _make_controller()
	# Up is checked first, then down, left, right — simultaneous presses must
	# resolve deterministically to the highest-priority held action.
	Input.action_press("move_up")
	Input.action_press("move_right")
	assert_that(controller._poll_direction()).is_equal(Vector2i.UP)
	Input.action_release("move_up")
	# With up released, down outranks the still-held right.
	Input.action_press("move_down")
	assert_that(controller._poll_direction()).is_equal(Vector2i.DOWN)

func test_eating_food_grows_snake_and_increments_score() -> void:
	var controller := _make_controller()
	# Put food directly ahead of the head so the next tick eats it.
	controller.food_position = controller.snake.get_head() + controller.snake.direction
	var eaten := controller.food_position
	controller._on_tick()
	assert_array(controller.snake.body).has_size(4)
	assert_that(controller.snake.get_head()).is_equal(eaten)
	assert_int(controller.score).is_equal(1)

func test_eating_food_respawns_it_off_the_snake() -> void:
	var controller := _make_controller()
	controller.food_position = controller.snake.get_head() + controller.snake.direction
	controller._on_tick()
	# Food moved to a fresh interior cell that isn't under the (grown) snake.
	assert_bool(Grid.is_border_cell(controller.food_position)).is_false()
	assert_bool(controller.snake.body.has(controller.food_position)).is_false()

func test_tick_without_food_ahead_does_not_grow_or_score() -> void:
	var controller := _make_controller()
	# Park food far from the head's path; a plain step must not eat it.
	controller.food_position = Vector2i(1, 1)
	controller._on_tick()
	assert_array(controller.snake.body).has_size(3)
	assert_int(controller.score).is_equal(0)

func test_tick_into_wall_triggers_game_over() -> void:
	var controller := _make_controller()
	# Position the head one cell inside the right border, moving right; the next
	# step lands on the border column and must end the game.
	var head := Vector2i(Grid.GRID_WIDTH - 2, 5)
	controller.snake.body = [head, head - Vector2i.RIGHT, head - Vector2i.RIGHT * 2]
	controller.snake.direction = Vector2i.RIGHT
	controller.food_position = Vector2i(1, 1)
	controller._on_tick()
	assert_int(controller.state).is_equal(GameController.GameState.GAME_OVER)
	assert_bool(controller.tick_timer.is_stopped()).is_true()

func test_tick_into_self_triggers_game_over() -> void:
	var controller := _make_controller()
	# Curl the body so a leftward step lands the head on (4,5) — a mid-body
	# segment, not the tail (5,5)->(4,4), so it can't be excused as a vacated tail.
	controller.snake.body = [
		Vector2i(5, 5), Vector2i(5, 6), Vector2i(5, 7),
		Vector2i(4, 7), Vector2i(4, 6), Vector2i(4, 5), Vector2i(4, 4),
	]
	controller.snake.direction = Vector2i.LEFT
	controller.food_position = Vector2i(1, 1)
	controller._on_tick()
	assert_int(controller.state).is_equal(GameController.GameState.GAME_OVER)

func test_eating_food_does_not_trigger_game_over() -> void:
	var controller := _make_controller()
	# Food directly ahead of an interior head: eating must not be read as a hit.
	controller.food_position = controller.snake.get_head() + controller.snake.direction
	controller._on_tick()
	assert_int(controller.state).is_equal(GameController.GameState.PLAYING)

func test_safe_tick_keeps_playing() -> void:
	var controller := _make_controller()
	# Plain interior step away from food: the game stays live.
	controller.food_position = Vector2i(1, 1)
	controller._on_tick()
	assert_int(controller.state).is_equal(GameController.GameState.PLAYING)

# --- UI tests ---
# The bare _make_controller() helper has no labels (built via .new()), so UI tests
# instantiate the full Main.tscn where ScoreLabel/GameOverLabel exist and @onready
# resolves them.
const MainScene := preload("res://Main.tscn")

func _make_scene_controller() -> GameController:
	var controller: GameController = auto_free(MainScene.instantiate())
	add_child(controller)
	return controller

func test_score_label_shows_current_score_while_playing() -> void:
	var controller := _make_scene_controller()
	controller.score = 4
	controller.update_ui()
	assert_str(controller.score_label.text).is_equal("Score: 4")
	assert_bool(controller.score_label.visible).is_true()

func test_game_over_label_hidden_while_playing() -> void:
	var controller := _make_scene_controller()
	# Fresh scene starts PLAYING via _ready -> reset_game -> update_ui.
	assert_bool(controller.game_over_label.visible).is_false()

func test_game_over_swaps_visible_labels() -> void:
	var controller := _make_scene_controller()
	controller.game_over()
	assert_bool(controller.score_label.visible).is_false()
	assert_bool(controller.game_over_label.visible).is_true()

func test_game_over_label_text_reports_score_and_high_score() -> void:
	var controller := _make_scene_controller()
	controller.high_score = 10
	controller.score = 6
	controller.game_over()
	var expected := "GAME OVER\nScore: 6\nHigh Score: 10\nPress any key to restart"
	assert_str(controller.game_over_label.text).is_equal(expected)

func test_reset_after_game_over_restores_playing_ui() -> void:
	var controller := _make_scene_controller()
	controller.game_over()
	controller.reset_game()
	assert_bool(controller.score_label.visible).is_true()
	assert_bool(controller.game_over_label.visible).is_false()
	assert_str(controller.score_label.text).is_equal("Score: 0")

# --- Audio tests ---
# Audio players exist only in Main.tscn, so these use the scene controller. The
# bare .new() controller leaves eat_sound/death_sound null; the null-guarded
# play() calls are covered by the eating/game_over tests above not crashing.

func test_scene_wires_up_audio_players_with_streams() -> void:
	var controller := _make_scene_controller()
	assert_object(controller.eat_sound).is_not_null()
	assert_object(controller.death_sound).is_not_null()
	assert_object(controller.eat_sound.stream).is_not_null()
	assert_object(controller.death_sound.stream).is_not_null()

func test_eating_food_plays_eat_sound() -> void:
	var controller := _make_scene_controller()
	controller.food_position = controller.snake.get_head() + controller.snake.direction
	controller._on_tick()
	assert_bool(controller.eat_sound.playing).is_true()

func test_game_over_plays_death_sound() -> void:
	var controller := _make_scene_controller()
	controller.game_over()
	assert_bool(controller.death_sound.playing).is_true()

func test_bare_controller_has_no_audio_players() -> void:
	# Built via .new(), the controller has no scene children, so the @onready
	# audio lookups resolve to null — the precondition the play() guards protect.
	var controller := _make_controller()
	assert_object(controller.eat_sound).is_null()
	assert_object(controller.death_sound).is_null()

func test_eating_food_without_audio_node_does_not_crash() -> void:
	# Null eat_sound: the guarded eat_sound.play() must be skipped, not crash.
	var controller := _make_controller()
	controller.food_position = controller.snake.get_head() + controller.snake.direction
	controller._on_tick()
	assert_int(controller.score).is_equal(1)

func test_game_over_without_audio_node_does_not_crash() -> void:
	# Null death_sound: the guarded death_sound.play() must be skipped, not crash.
	var controller := _make_controller()
	controller.game_over()
	assert_int(controller.state).is_equal(GameController.GameState.GAME_OVER)

# --- Visual rendering tests ---
# _ready -> reset_game -> update_visuals builds the initial snake sprites. Tests
# that re-call update_visuals await one frame so the queue_free'd old sprites are
# gone before inspecting snake_visuals' children (queue_free is deferred).

const CENTER := Vector2(Grid.CELL_SIZE / 2.0, Grid.CELL_SIZE / 2.0)

func test_ready_creates_visual_nodes() -> void:
	var controller := _make_controller()
	assert_object(controller.snake_visuals).is_not_null()
	assert_object(controller.food_sprite).is_not_null()
	assert_object(controller.food_sprite.texture).is_same(GameController.FOOD_SPRITE)

func test_update_visuals_creates_one_sprite_per_segment() -> void:
	var controller := _make_controller()
	# Fresh build from _ready: 3-segment snake, no pending frees yet.
	assert_int(controller.snake_visuals.get_child_count()).is_equal(controller.snake.body.size())

func test_head_sprite_uses_head_texture_and_body_uses_body_texture() -> void:
	var controller := _make_controller()
	var head: Sprite2D = controller.snake_visuals.get_child(0)
	var body: Sprite2D = controller.snake_visuals.get_child(1)
	assert_object(head.texture).is_same(GameController.HEAD_SPRITE)
	assert_object(body.texture).is_same(GameController.BODY_SPRITE)

func test_segments_are_centered_on_their_cells() -> void:
	var controller := _make_controller()
	for i in controller.snake.body.size():
		var sprite: Sprite2D = controller.snake_visuals.get_child(i)
		var expected := Grid.cell_to_pixel(controller.snake.body[i]) + CENTER
		assert_that(sprite.position).is_equal(expected)

func test_food_sprite_tracks_food_position() -> void:
	var controller := _make_controller()
	assert_that(controller.food_sprite.position).is_equal(Grid.cell_to_pixel(controller.food_position) + CENTER)

func test_head_rotation_matches_direction() -> void:
	var controller := _make_controller()
	for dir_deg in [
		[Vector2i.RIGHT, 0.0], [Vector2i.UP, -90.0],
		[Vector2i.LEFT, 180.0], [Vector2i.DOWN, 90.0],
	]:
		# Reset the body so set_direction never rejects the turn as a reversal.
		controller.snake.body = [Vector2i(10, 7)]
		controller.snake.direction = dir_deg[0]
		controller.update_visuals()
		await get_tree().process_frame  # let the prior build's sprites free
		var head: Sprite2D = controller.snake_visuals.get_child(0)
		assert_float(head.rotation_degrees).is_equal(dir_deg[1])

func test_rebuild_does_not_stack_duplicate_sprites() -> void:
	var controller := _make_controller()
	controller.update_visuals()
	await get_tree().process_frame
	assert_int(controller.snake_visuals.get_child_count()).is_equal(controller.snake.body.size())
