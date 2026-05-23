extends GdUnitTestSuite

const EXPECTED_ACTIONS := [
	"move_up",
	"move_down",
	"move_left",
	"move_right",
	"start",
	"restart",
]

func test_all_expected_actions_exist() -> void:
	for action in EXPECTED_ACTIONS:
		assert_bool(InputMap.has_action(action)) \
			.override_failure_message("Missing input action: %s" % action) \
			.is_true()

func test_move_up_bound_to_w_and_up() -> void:
	var keycodes := _keycodes_for("move_up")
	assert_array(keycodes).contains([KEY_W, KEY_UP])

func test_move_down_bound_to_s_and_down() -> void:
	var keycodes := _keycodes_for("move_down")
	assert_array(keycodes).contains([KEY_S, KEY_DOWN])

func test_move_left_bound_to_a_and_left() -> void:
	var keycodes := _keycodes_for("move_left")
	assert_array(keycodes).contains([KEY_A, KEY_LEFT])

func test_move_right_bound_to_d_and_right() -> void:
	var keycodes := _keycodes_for("move_right")
	assert_array(keycodes).contains([KEY_D, KEY_RIGHT])

func test_start_bound_to_enter() -> void:
	var keycodes := _keycodes_for("start")
	assert_array(keycodes).contains([KEY_ENTER])

func test_restart_bound_to_r() -> void:
	var keycodes := _keycodes_for("restart")
	assert_array(keycodes).contains([KEY_R])

func _keycodes_for(action: String) -> Array[int]:
	var keycodes: Array[int] = []
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			var code := key_event.keycode if key_event.keycode != 0 else key_event.physical_keycode
			keycodes.append(code)
	return keycodes
