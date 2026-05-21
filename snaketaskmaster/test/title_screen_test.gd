extends GdUnitTestSuite

const TITLE_SCENE_PATH := "res://scenes/TitleScreen.tscn"


func _make_title() -> TitleScreen:
	var title: TitleScreen = auto_free(load(TITLE_SCENE_PATH).instantiate())
	add_child(title)
	# Disconnect the default scene-change handler so tests can fire input
	# without actually swapping out the active scene.
	if title.start_game_requested.is_connected(title._on_start_game_requested):
		title.start_game_requested.disconnect(title._on_start_game_requested)
	return title


func test_root_is_control() -> void:
	var title: TitleScreen = _make_title()
	assert_bool(title is Control).is_true()


func test_title_label_text() -> void:
	var title: TitleScreen = _make_title()
	var label: Label = title.get_node("VBoxContainer/TitleLabel")
	assert_str(label.text).is_equal("SNAKE")


func test_prompt_label_text() -> void:
	var title: TitleScreen = _make_title()
	var label: Label = title.get_node("VBoxContainer/PromptLabel")
	assert_str(label.text).is_equal("Press Enter to Start")


func test_title_label_font_size() -> void:
	var title: TitleScreen = _make_title()
	var label: Label = title.get_node("VBoxContainer/TitleLabel")
	assert_int(label.get_theme_font_size("font_size")).is_equal(48)


func test_prompt_label_font_size() -> void:
	var title: TitleScreen = _make_title()
	var label: Label = title.get_node("VBoxContainer/PromptLabel")
	assert_int(label.get_theme_font_size("font_size")).is_equal(18)


func test_gameplay_scene_path_exists() -> void:
	assert_bool(ResourceLoader.exists(TitleScreen.GAMEPLAY_SCENE_PATH)).is_true()


func test_input_start_action_emits_signal() -> void:
	var title: TitleScreen = _make_title()
	var emitted := [false]
	title.start_game_requested.connect(func() -> void: emitted[0] = true)
	var event := InputEventAction.new()
	event.action = "start"
	event.pressed = true
	title._input(event)
	assert_bool(emitted[0]).is_true()


func test_input_non_start_action_does_not_emit_signal() -> void:
	var title: TitleScreen = _make_title()
	var emitted := [false]
	title.start_game_requested.connect(func() -> void: emitted[0] = true)
	var event := InputEventAction.new()
	event.action = "move_up"
	event.pressed = true
	title._input(event)
	assert_bool(emitted[0]).is_false()
