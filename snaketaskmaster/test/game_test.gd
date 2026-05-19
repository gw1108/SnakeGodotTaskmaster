extends GdUnitTestSuite

const GAME_SCENE_PATH := "res://scenes/game.tscn"

func test_game_scene_file_exists() -> void:
	assert_file(GAME_SCENE_PATH).exists()

func test_game_scene_instantiates_with_required_children() -> void:
	var packed := load(GAME_SCENE_PATH) as PackedScene
	assert_object(packed).is_not_null()
	var game: Node2D = auto_free(packed.instantiate())
	add_child(game)
	assert_str(game.name).is_equal("Game")
	assert_object(game).is_instanceof(Node2D)
	var playfield := game.get_node_or_null("Playfield")
	var hud := game.get_node_or_null("HUD")
	var sm := game.get_node_or_null("GameStateMachine")
	assert_object(playfield).is_not_null()
	assert_object(hud).is_not_null()
	assert_object(sm).is_not_null()
	assert_object(playfield).is_instanceof(Node2D)
	assert_object(hud).is_instanceof(CanvasLayer)

func test_input_actions_defined() -> void:
	for action in ["move_up", "move_down", "move_left", "move_right"]:
		assert_bool(InputMap.has_action(action)).is_true()
		assert_int(InputMap.action_get_events(action).size()).is_greater_equal(2)

func test_input_action_key_bindings() -> void:
	var expected := {
		"move_up":    [KEY_UP, KEY_W],
		"move_down":  [KEY_DOWN, KEY_S],
		"move_left":  [KEY_LEFT, KEY_A],
		"move_right": [KEY_RIGHT, KEY_D],
	}
	for action in expected.keys():
		var keycodes: Array[int] = []
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey:
				keycodes.append((ev as InputEventKey).keycode)
		for expected_key in expected[action]:
			assert_bool(expected_key in keycodes).is_true()

func test_viewport_dimensions() -> void:
	assert_int(ProjectSettings.get_setting("display/window/size/viewport_width")).is_equal(640)
	assert_int(ProjectSettings.get_setting("display/window/size/viewport_height")).is_equal(480)

func test_main_scene_points_at_game_tscn() -> void:
	assert_str(ProjectSettings.get_setting("application/run/main_scene")).is_equal(GAME_SCENE_PATH)
