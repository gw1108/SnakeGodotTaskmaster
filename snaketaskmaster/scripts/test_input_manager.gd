extends SceneTree


func _make_key_event(keycode: int) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.pressed = true
	return ev


func _initialize() -> void:
	create_timer(10.0).timeout.connect(func() -> void:
		printerr("FAIL: test exceeded 10s safety timeout")
		quit(2))
	var IM = load("res://scripts/input_manager.gd").new()
	get_root().add_child(IM)
	var failures: Array[String] = []

	# WASD mapping
	IM._input(_make_key_event(KEY_W))
	var d: Vector2i = IM.get_buffered_direction(Vector2i.ZERO)
	if d != Vector2i(0, -1):
		failures.append("W expected (0,-1) got %s" % d)

	IM._input(_make_key_event(KEY_S))
	d = IM.get_buffered_direction(Vector2i.ZERO)
	if d != Vector2i(0, 1):
		failures.append("S expected (0,1) got %s" % d)

	IM._input(_make_key_event(KEY_A))
	d = IM.get_buffered_direction(Vector2i.ZERO)
	if d != Vector2i(-1, 0):
		failures.append("A expected (-1,0) got %s" % d)

	IM._input(_make_key_event(KEY_D))
	d = IM.get_buffered_direction(Vector2i.ZERO)
	if d != Vector2i(1, 0):
		failures.append("D expected (1,0) got %s" % d)

	# Arrow key mapping (via ui_* actions)
	IM._input(_make_key_event(KEY_UP))
	d = IM.get_buffered_direction(Vector2i.ZERO)
	if d != Vector2i(0, -1):
		failures.append("KEY_UP expected (0,-1) got %s" % d)

	IM._input(_make_key_event(KEY_DOWN))
	d = IM.get_buffered_direction(Vector2i.ZERO)
	if d != Vector2i(0, 1):
		failures.append("KEY_DOWN expected (0,1) got %s" % d)

	IM._input(_make_key_event(KEY_LEFT))
	d = IM.get_buffered_direction(Vector2i.ZERO)
	if d != Vector2i(-1, 0):
		failures.append("KEY_LEFT expected (-1,0) got %s" % d)

	IM._input(_make_key_event(KEY_RIGHT))
	d = IM.get_buffered_direction(Vector2i.ZERO)
	if d != Vector2i(1, 0):
		failures.append("KEY_RIGHT expected (1,0) got %s" % d)

	# Empty buffer returns current direction
	d = IM.get_buffered_direction(Vector2i(1, 0))
	if d != Vector2i(1, 0):
		failures.append("empty buffer expected (1,0) got %s" % d)

	# 180-degree reversal blocked: going RIGHT, press LEFT -> still RIGHT
	IM._input(_make_key_event(KEY_A))
	d = IM.get_buffered_direction(Vector2i(1, 0))
	if d != Vector2i(1, 0):
		failures.append("LEFT while RIGHT expected (1,0) got %s" % d)

	# 180-degree reversal blocked: going UP, press DOWN -> still UP
	IM._input(_make_key_event(KEY_S))
	d = IM.get_buffered_direction(Vector2i(0, -1))
	if d != Vector2i(0, -1):
		failures.append("DOWN while UP expected (0,-1) got %s" % d)

	# Perpendicular turn allowed: going RIGHT, press UP -> UP
	IM._input(_make_key_event(KEY_W))
	d = IM.get_buffered_direction(Vector2i(1, 0))
	if d != Vector2i(0, -1):
		failures.append("UP while RIGHT expected (0,-1) got %s" % d)

	# Buffer cleared after retrieval (even when blocked)
	IM._input(_make_key_event(KEY_A))
	var _consumed: Vector2i = IM.get_buffered_direction(Vector2i(1, 0))
	d = IM.get_buffered_direction(Vector2i(1, 0))
	if d != Vector2i(1, 0):
		failures.append("buffer not cleared after blocked retrieval got %s" % d)

	# Latest input wins when multiple presses occur between ticks
	IM._input(_make_key_event(KEY_W))
	IM._input(_make_key_event(KEY_D))
	d = IM.get_buffered_direction(Vector2i.ZERO)
	if d != Vector2i(1, 0):
		failures.append("latest input expected (1,0) got %s" % d)

	if failures.is_empty():
		print("OK: all InputManager tests passed")
		quit(0)
	else:
		for f in failures:
			printerr("FAIL: ", f)
		quit(1)
