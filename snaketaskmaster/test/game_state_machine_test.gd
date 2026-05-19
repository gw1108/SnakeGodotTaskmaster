extends GdUnitTestSuite

const GSM_SCRIPT_PATH := "res://scripts/game_state_machine.gd"

var _PLAYING: int
var _GAME_OVER: int


func before_test() -> void:
	var state_enum: Dictionary = _gsm_script().get_script_constant_map()["State"]
	_PLAYING = state_enum["PLAYING"]
	_GAME_OVER = state_enum["GAME_OVER"]


func _gsm_script() -> GDScript:
	return load(GSM_SCRIPT_PATH) as GDScript


func _make_sm() -> Node:
	var sm: Node = auto_free(Node.new())
	sm.set_script(_gsm_script())
	add_child(sm)
	return sm


func test_script_file_exists() -> void:
	assert_file(GSM_SCRIPT_PATH).exists()


func test_enum_state_keys() -> void:
	var consts := _gsm_script().get_script_constant_map()
	assert_dict(consts).contains_keys(["State"])
	var state_enum: Dictionary = consts["State"]
	assert_dict(state_enum).contains_keys(["PLAYING", "GAME_OVER"])
	assert_int(state_enum["PLAYING"]).is_not_equal(state_enum["GAME_OVER"])


func test_initial_state_is_playing() -> void:
	var sm := _make_sm()
	assert_int(sm.current_state).is_equal(_PLAYING)


func test_state_changed_signal_declared() -> void:
	var sm := _make_sm()
	var found := false
	for s in sm.get_signal_list():
		if s["name"] == "state_changed":
			found = true
			break
	assert_bool(found).is_true()


func test_transition_to_updates_current_state() -> void:
	var sm := _make_sm()
	sm.transition_to(_GAME_OVER)
	assert_int(sm.current_state).is_equal(_GAME_OVER)


func test_transition_to_emits_state_changed_with_new_state() -> void:
	var sm := _make_sm()
	var received: Array[int] = [-1]
	var fired: Array[int] = [0]
	sm.state_changed.connect(func(new_state: int) -> void:
		received[0] = new_state
		fired[0] += 1
	)
	sm.transition_to(_GAME_OVER)
	assert_int(fired[0]).is_equal(1)
	assert_int(received[0]).is_equal(_GAME_OVER)


func test_transition_to_same_state_no_op() -> void:
	var sm := _make_sm()
	var fired: Array[int] = [0]
	sm.state_changed.connect(func(_new_state: int) -> void: fired[0] += 1)
	sm.transition_to(_PLAYING)
	assert_int(fired[0]).is_equal(0)
	assert_int(sm.current_state).is_equal(_PLAYING)


func test_playing_to_game_over_to_playing_round_trip() -> void:
	var sm := _make_sm()
	var received: Array = []
	sm.state_changed.connect(func(new_state: int) -> void: received.append(new_state))
	sm.transition_to(_GAME_OVER)
	sm.transition_to(_PLAYING)
	assert_array(received).has_size(2)
	assert_int(received[0]).is_equal(_GAME_OVER)
	assert_int(received[1]).is_equal(_PLAYING)
	assert_int(sm.current_state).is_equal(_PLAYING)


func test_transition_emits_only_for_distinct_states() -> void:
	var sm := _make_sm()
	var fired: Array[int] = [0]
	sm.state_changed.connect(func(_new_state: int) -> void: fired[0] += 1)
	sm.transition_to(_PLAYING)
	sm.transition_to(_PLAYING)
	sm.transition_to(_GAME_OVER)
	sm.transition_to(_GAME_OVER)
	sm.transition_to(_PLAYING)
	assert_int(fired[0]).is_equal(2)


func test_integration_game_scene_state_machine_controls_game_tick() -> void:
	var packed := load("res://scenes/game.tscn") as PackedScene
	var game: Node2D = auto_free(packed.instantiate())
	add_child(game)
	var sm := game.get_node_or_null("GameStateMachine") as Node
	var gt := game.get_node_or_null("GameTick") as Node
	assert_object(sm).is_not_null()
	assert_object(gt).is_not_null()
	# Initial state is PLAYING but no transition has fired — game_tick remains stopped
	assert_bool(gt.is_running()).is_false()
	# Transition to GAME_OVER from PLAYING — stop_tick is idempotent
	sm.transition_to(_GAME_OVER)
	assert_int(sm.current_state).is_equal(_GAME_OVER)
	assert_bool(gt.is_running()).is_false()
	# GAME_OVER → PLAYING should start the tick
	sm.transition_to(_PLAYING)
	assert_int(sm.current_state).is_equal(_PLAYING)
	assert_bool(gt.is_running()).is_true()
	# PLAYING → GAME_OVER should stop the tick
	sm.transition_to(_GAME_OVER)
	assert_bool(gt.is_running()).is_false()
