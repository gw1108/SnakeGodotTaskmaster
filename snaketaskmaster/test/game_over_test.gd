extends GdUnitTestSuite

const GAME_OVER_SCENE_PATH := "res://scenes/GameOver.tscn"


func before_test() -> void:
	# Tests below read GameState.current_score; isolate them from each other.
	GameState.set_score(0)


func after_test() -> void:
	GameState.set_score(0)


func _make_game_over() -> GameOver:
	var game_over: GameOver = auto_free(load(GAME_OVER_SCENE_PATH).instantiate())
	add_child(game_over)
	# Disconnect the default scene-change handler so tests can fire input
	# without actually swapping out the active scene.
	if game_over.restart_requested.is_connected(game_over._on_restart_requested):
		game_over.restart_requested.disconnect(game_over._on_restart_requested)
	return game_over


func test_root_is_control() -> void:
	var game_over: GameOver = _make_game_over()
	assert_bool(game_over is Control).is_true()


func test_game_over_label_text() -> void:
	var game_over: GameOver = _make_game_over()
	var label: Label = game_over.get_node("VBoxContainer/GameOverLabel")
	assert_str(label.text).is_equal("GAME OVER")


func test_restart_prompt_label_text() -> void:
	var game_over: GameOver = _make_game_over()
	var label: Label = game_over.get_node("VBoxContainer/RestartLabel")
	assert_str(label.text).is_equal("Press R to Restart")


func test_game_over_label_font_size() -> void:
	var game_over: GameOver = _make_game_over()
	var label: Label = game_over.get_node("VBoxContainer/GameOverLabel")
	assert_int(label.get_theme_font_size("font_size")).is_equal(36)


func test_score_label_font_size() -> void:
	var game_over: GameOver = _make_game_over()
	var label: Label = game_over.get_node("VBoxContainer/ScoreLabel")
	assert_int(label.get_theme_font_size("font_size")).is_equal(24)


func test_restart_prompt_label_font_size() -> void:
	var game_over: GameOver = _make_game_over()
	var label: Label = game_over.get_node("VBoxContainer/RestartLabel")
	assert_int(label.get_theme_font_size("font_size")).is_equal(18)


func test_initial_final_score_is_zero_when_state_empty() -> void:
	var game_over: GameOver = _make_game_over()
	assert_int(game_over.final_score).is_equal(0)
	var label: Label = game_over.get_node("VBoxContainer/ScoreLabel")
	assert_str(label.text).is_equal("Score: 0")


func test_game_state_score_applied_on_ready() -> void:
	GameState.set_score(7)
	var game_over: GameOver = _make_game_over()
	assert_int(game_over.final_score).is_equal(7)
	var label: Label = game_over.get_node("VBoxContainer/ScoreLabel")
	assert_str(label.text).is_equal("Score: 7")


func test_set_score_updates_label() -> void:
	var game_over: GameOver = _make_game_over()
	game_over.set_score(10)
	var label: Label = game_over.get_node("VBoxContainer/ScoreLabel")
	assert_int(game_over.final_score).is_equal(10)
	assert_str(label.text).is_equal("Score: 10")


func test_gameplay_scene_path_exists() -> void:
	assert_bool(ResourceLoader.exists(GameOver.GAMEPLAY_SCENE_PATH)).is_true()


func test_input_restart_action_emits_signal() -> void:
	var game_over: GameOver = _make_game_over()
	var emitted := [false]
	game_over.restart_requested.connect(func() -> void: emitted[0] = true)
	var event := InputEventAction.new()
	event.action = "restart"
	event.pressed = true
	game_over._input(event)
	assert_bool(emitted[0]).is_true()


func test_input_non_restart_action_does_not_emit_signal() -> void:
	var game_over: GameOver = _make_game_over()
	var emitted := [false]
	game_over.restart_requested.connect(func() -> void: emitted[0] = true)
	var event := InputEventAction.new()
	event.action = "move_up"
	event.pressed = true
	game_over._input(event)
	assert_bool(emitted[0]).is_false()
