extends GdUnitTestSuite

const INPUT_HANDLER_SCRIPT_PATH := "res://scripts/input_handler.gd"
const InputHandlerScript := preload("res://scripts/input_handler.gd")


func _make_handler() -> Node:
	var h: Node = auto_free(InputHandlerScript.new())
	add_child(h)
	return h


func _press(handler: Node, keycode: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.pressed = true
	handler._input(ev)


func test_script_file_exists() -> void:
	assert_file(INPUT_HANDLER_SCRIPT_PATH).exists()


func test_direction_enum_has_four_values_in_order() -> void:
	var keys: Array = InputHandlerScript.Direction.keys()
	assert_array(keys).is_equal(["UP", "DOWN", "LEFT", "RIGHT"])


func test_initial_state() -> void:
	var h := _make_handler()
	assert_int(h.current_direction).is_equal(InputHandlerScript.Direction.RIGHT)
	assert_that(h.buffered_direction).is_null()


func test_arrow_up_buffers_up_from_right() -> void:
	var h := _make_handler()
	_press(h, KEY_UP)
	assert_int(h.buffered_direction).is_equal(InputHandlerScript.Direction.UP)


func test_arrow_down_buffers_down_from_right() -> void:
	var h := _make_handler()
	_press(h, KEY_DOWN)
	assert_int(h.buffered_direction).is_equal(InputHandlerScript.Direction.DOWN)


func test_wasd_keys_each_buffer_their_direction_in_legal_sequence() -> void:
	# Walk a legal sequence so each key is perpendicular (legal) to the
	# previously-consumed direction.
	var h := _make_handler()
	_press(h, KEY_W)
	assert_int(h.consume_buffered_direction()).is_equal(InputHandlerScript.Direction.UP)
	_press(h, KEY_A)
	assert_int(h.consume_buffered_direction()).is_equal(InputHandlerScript.Direction.LEFT)
	_press(h, KEY_S)
	assert_int(h.consume_buffered_direction()).is_equal(InputHandlerScript.Direction.DOWN)
	_press(h, KEY_D)
	assert_int(h.consume_buffered_direction()).is_equal(InputHandlerScript.Direction.RIGHT)


func test_all_reversals_rejected() -> void:
	# (current_direction, opposite_keycode)
	var cases := [
		[InputHandlerScript.Direction.UP, KEY_DOWN],
		[InputHandlerScript.Direction.DOWN, KEY_UP],
		[InputHandlerScript.Direction.LEFT, KEY_RIGHT],
		[InputHandlerScript.Direction.RIGHT, KEY_LEFT],
		# WASD variants too
		[InputHandlerScript.Direction.UP, KEY_S],
		[InputHandlerScript.Direction.DOWN, KEY_W],
		[InputHandlerScript.Direction.LEFT, KEY_D],
		[InputHandlerScript.Direction.RIGHT, KEY_A],
	]
	for case in cases:
		var h := _make_handler()
		h.current_direction = case[0]
		_press(h, case[1])
		assert_that(h.buffered_direction).is_null()


func test_legal_perpendiculars_are_buffered() -> void:
	# (current_direction, pressed_keycode, expected_buffered)
	var cases := [
		[InputHandlerScript.Direction.UP, KEY_LEFT, InputHandlerScript.Direction.LEFT],
		[InputHandlerScript.Direction.UP, KEY_RIGHT, InputHandlerScript.Direction.RIGHT],
		[InputHandlerScript.Direction.DOWN, KEY_LEFT, InputHandlerScript.Direction.LEFT],
		[InputHandlerScript.Direction.DOWN, KEY_RIGHT, InputHandlerScript.Direction.RIGHT],
		[InputHandlerScript.Direction.LEFT, KEY_UP, InputHandlerScript.Direction.UP],
		[InputHandlerScript.Direction.LEFT, KEY_DOWN, InputHandlerScript.Direction.DOWN],
		[InputHandlerScript.Direction.RIGHT, KEY_UP, InputHandlerScript.Direction.UP],
		[InputHandlerScript.Direction.RIGHT, KEY_DOWN, InputHandlerScript.Direction.DOWN],
	]
	for case in cases:
		var h := _make_handler()
		h.current_direction = case[0]
		_press(h, case[1])
		assert_int(h.buffered_direction).is_equal(case[2])


func test_consume_returns_buffered_and_resets_and_updates_current() -> void:
	var h := _make_handler()
	_press(h, KEY_UP)
	var next: int = h.consume_buffered_direction()
	assert_int(next).is_equal(InputHandlerScript.Direction.UP)
	assert_that(h.buffered_direction).is_null()
	assert_int(h.current_direction).is_equal(InputHandlerScript.Direction.UP)


func test_consume_with_no_buffer_returns_current_unchanged() -> void:
	var h := _make_handler()
	h.current_direction = InputHandlerScript.Direction.DOWN
	var result: int = h.consume_buffered_direction()
	assert_int(result).is_equal(InputHandlerScript.Direction.DOWN)
	assert_int(h.current_direction).is_equal(InputHandlerScript.Direction.DOWN)
	assert_that(h.buffered_direction).is_null()


func test_latest_legal_input_overwrites_buffer() -> void:
	var h := _make_handler()
	# current=RIGHT, UP legal, then DOWN also legal (perpendicular to RIGHT)
	_press(h, KEY_UP)
	assert_int(h.buffered_direction).is_equal(InputHandlerScript.Direction.UP)
	_press(h, KEY_DOWN)
	assert_int(h.buffered_direction).is_equal(InputHandlerScript.Direction.DOWN)


func test_rejected_input_preserves_existing_buffer() -> void:
	var h := _make_handler()
	# current=RIGHT; UP legal, LEFT is reversal → rejected, buffer stays UP
	_press(h, KEY_UP)
	assert_int(h.buffered_direction).is_equal(InputHandlerScript.Direction.UP)
	_press(h, KEY_LEFT)
	assert_int(h.buffered_direction).is_equal(InputHandlerScript.Direction.UP)


func test_key_release_does_not_buffer() -> void:
	var h := _make_handler()
	var ev := InputEventKey.new()
	ev.keycode = KEY_UP
	ev.pressed = false
	h._input(ev)
	assert_that(h.buffered_direction).is_null()


func test_echo_event_does_not_buffer() -> void:
	var h := _make_handler()
	var ev := InputEventKey.new()
	ev.keycode = KEY_UP
	ev.pressed = true
	ev.echo = true
	h._input(ev)
	assert_that(h.buffered_direction).is_null()


func test_unrelated_keys_do_not_buffer() -> void:
	var h := _make_handler()
	_press(h, KEY_SPACE)
	assert_that(h.buffered_direction).is_null()
	_press(h, KEY_ENTER)
	assert_that(h.buffered_direction).is_null()
