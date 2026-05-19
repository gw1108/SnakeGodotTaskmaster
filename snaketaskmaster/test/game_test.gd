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


const GameStateMachineScript := preload("res://scripts/game_state_machine.gd")


func _make_game() -> Node2D:
	var game: Node2D = auto_free((load(GAME_SCENE_PATH) as PackedScene).instantiate())
	add_child(game)
	return game


func test_game_initially_hides_game_over_panel() -> void:
	var game := _make_game()
	var panel: Panel = game.get_node("HUD/GameOverPanel")
	assert_bool(panel.visible).is_false()


func test_game_shows_game_over_overlay_on_state_change_to_game_over() -> void:
	var game := _make_game()
	game.score = 5
	var sm: Node = game.get_node("GameStateMachine")
	sm.transition_to(GameStateMachineScript.State.GAME_OVER)
	var panel: Panel = game.get_node("HUD/GameOverPanel")
	var final_label: Label = game.get_node("HUD/GameOverPanel/VBoxContainer/FinalScoreLabel")
	assert_bool(panel.visible).is_true()
	assert_str(final_label.text).is_equal("Final Score: 5")


func test_game_hides_overlay_when_returning_to_playing() -> void:
	var game := _make_game()
	var sm: Node = game.get_node("GameStateMachine")
	sm.transition_to(GameStateMachineScript.State.GAME_OVER)
	sm.transition_to(GameStateMachineScript.State.PLAYING)
	var panel: Panel = game.get_node("HUD/GameOverPanel")
	assert_bool(panel.visible).is_false()


func test_key_press_in_playing_state_does_not_trigger_restart() -> void:
	var game := _make_game()
	game.score = 9
	# State is PLAYING by default; key press should be ignored.
	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	event.pressed = true
	game._input(event)
	assert_int(game.score).is_equal(9)


func test_key_press_in_game_over_calls_restart() -> void:
	var game := _make_game()
	game.score = 12
	var sm: Node = game.get_node("GameStateMachine")
	sm.transition_to(GameStateMachineScript.State.GAME_OVER)
	# Simulate any key press.
	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	event.pressed = true
	game._input(event)
	assert_int(game.score).is_equal(0)
	assert_int(sm.current_state).is_equal(GameStateMachineScript.State.PLAYING)


func test_key_release_in_game_over_ignored() -> void:
	var game := _make_game()
	game.score = 7
	var sm: Node = game.get_node("GameStateMachine")
	sm.transition_to(GameStateMachineScript.State.GAME_OVER)
	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	event.pressed = false
	game._input(event)
	# Released key should not trigger restart.
	assert_int(sm.current_state).is_equal(GameStateMachineScript.State.GAME_OVER)
	assert_int(game.score).is_equal(7)


func test_key_echo_in_game_over_ignored() -> void:
	var game := _make_game()
	game.score = 4
	var sm: Node = game.get_node("GameStateMachine")
	sm.transition_to(GameStateMachineScript.State.GAME_OVER)
	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	event.pressed = true
	event.echo = true
	game._input(event)
	assert_int(sm.current_state).is_equal(GameStateMachineScript.State.GAME_OVER)
	assert_int(game.score).is_equal(4)


func test_restart_resets_score_and_transitions_to_playing() -> void:
	var game := _make_game()
	game.score = 99
	var sm: Node = game.get_node("GameStateMachine")
	sm.transition_to(GameStateMachineScript.State.GAME_OVER)
	game.restart()
	assert_int(game.score).is_equal(0)
	assert_int(sm.current_state).is_equal(GameStateMachineScript.State.PLAYING)
	var score_label: Label = game.get_node("HUD/ScoreLabel")
	assert_str(score_label.text).is_equal("Score: 0")
	var panel: Panel = game.get_node("HUD/GameOverPanel")
	assert_bool(panel.visible).is_false()


func test_restart_starts_game_tick() -> void:
	var game := _make_game()
	var sm: Node = game.get_node("GameStateMachine")
	var gt: Node = game.get_node("GameTick")
	# Trigger GAME_OVER to stop the tick first.
	sm.transition_to(GameStateMachineScript.State.GAME_OVER)
	assert_bool(gt.is_running()).is_false()
	game.restart()
	# transition_to(PLAYING) via restart should have started the tick.
	assert_bool(gt.is_running()).is_true()


func test_eat_sound_node_present_with_stream() -> void:
	var game := _make_game()
	var eat: AudioStreamPlayer = game.get_node("EatSound")
	assert_object(eat).is_not_null()
	assert_object(eat).is_instanceof(AudioStreamPlayer)
	assert_object(eat.stream).is_not_null()
	# Volume should not be deafening — sanity check ≤ 0 dB.
	assert_float(eat.volume_db).is_less_equal(0.0)
	assert_bool(eat.playing).is_false()


func test_on_food_eaten_plays_eat_sound() -> void:
	var game := _make_game()
	game._on_food_eaten()
	var eat: AudioStreamPlayer = game.get_node("EatSound")
	assert_bool(eat.playing).is_true()


func test_death_sound_node_present_with_stream() -> void:
	var game := _make_game()
	var death: AudioStreamPlayer = game.get_node("DeathSound")
	assert_object(death).is_not_null()
	assert_object(death).is_instanceof(AudioStreamPlayer)
	assert_object(death.stream).is_not_null()
	assert_float(death.volume_db).is_less_equal(0.0)
	assert_bool(death.playing).is_false()


func test_state_change_to_game_over_plays_death_sound() -> void:
	var game := _make_game()
	var sm: Node = game.get_node("GameStateMachine")
	sm.transition_to(GameStateMachineScript.State.GAME_OVER)
	var death: AudioStreamPlayer = game.get_node("DeathSound")
	assert_bool(death.playing).is_true()


func test_state_change_to_playing_does_not_play_death_sound() -> void:
	var game := _make_game()
	# Force into GAME_OVER first, stop the sound, then transition back to PLAYING.
	var sm: Node = game.get_node("GameStateMachine")
	sm.transition_to(GameStateMachineScript.State.GAME_OVER)
	var death: AudioStreamPlayer = game.get_node("DeathSound")
	death.stop()
	sm.transition_to(GameStateMachineScript.State.PLAYING)
	assert_bool(death.playing).is_false()


func test_food_eaten_signal_triggers_eat_sound() -> void:
	# Wire a Food child BEFORE adding the Game to the tree so game.gd._ready()
	# discovers it via get_node_or_null("Food") and connects the signal.
	var packed := load(GAME_SCENE_PATH) as PackedScene
	var game: Node2D = auto_free(packed.instantiate())
	var FoodScript := load("res://scripts/food.gd") as GDScript
	var food: Node = FoodScript.new()
	food.name = "Food"
	game.add_child(food)
	add_child(game)
	# Now emit the signal — game.gd should have connected to it.
	food.food_eaten.emit()
	var eat: AudioStreamPlayer = game.get_node("EatSound")
	assert_bool(eat.playing).is_true()
