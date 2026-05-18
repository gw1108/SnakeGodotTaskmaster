extends SceneTree


func _initialize() -> void:
	create_timer(10.0).timeout.connect(func() -> void:
		printerr("FAIL: test exceeded 10s safety timeout")
		quit(2))
	var GC = load("res://scripts/game_constants.gd").new()
	var failures: Array[String] = []

	if GC.GRID_WIDTH != 20:
		failures.append("GRID_WIDTH expected 20 got %s" % GC.GRID_WIDTH)
	if GC.GRID_HEIGHT != 15:
		failures.append("GRID_HEIGHT expected 15 got %s" % GC.GRID_HEIGHT)
	if GC.CELL_SIZE != 32:
		failures.append("CELL_SIZE expected 32 got %s" % GC.CELL_SIZE)
	if not is_equal_approx(GC.TICK_INTERVAL, 0.15):
		failures.append("TICK_INTERVAL expected 0.15 got %s" % GC.TICK_INTERVAL)

	var p00: Vector2 = GC.grid_to_pixel(Vector2i(0, 0))
	if not p00.is_equal_approx(Vector2(16, 16)):
		failures.append("grid_to_pixel(0,0) expected (16,16) got %s" % p00)

	var p1914: Vector2 = GC.grid_to_pixel(Vector2i(19, 14))
	if not p1914.is_equal_approx(Vector2(19 * 32 + 16, 14 * 32 + 16)):
		failures.append("grid_to_pixel(19,14) got %s" % p1914)

	var g_center: Vector2i = GC.pixel_to_grid(Vector2(16, 16))
	if g_center != Vector2i(0, 0):
		failures.append("pixel_to_grid(16,16) expected (0,0) got %s" % g_center)

	var g_edge: Vector2i = GC.pixel_to_grid(Vector2(63, 31))
	if g_edge != Vector2i(1, 0):
		failures.append("pixel_to_grid(63,31) expected (1,0) got %s" % g_edge)

	if not GC.is_valid_grid_pos(Vector2i(0, 0)):
		failures.append("is_valid_grid_pos(0,0) expected true")
	if not GC.is_valid_grid_pos(Vector2i(19, 14)):
		failures.append("is_valid_grid_pos(19,14) expected true")
	if GC.is_valid_grid_pos(Vector2i(-1, 0)):
		failures.append("is_valid_grid_pos(-1,0) expected false")
	if GC.is_valid_grid_pos(Vector2i(20, 0)):
		failures.append("is_valid_grid_pos(20,0) expected false")
	if GC.is_valid_grid_pos(Vector2i(0, 15)):
		failures.append("is_valid_grid_pos(0,15) expected false")

	if failures.is_empty():
		print("OK: all GameConstants tests passed")
		quit(0)
	else:
		for f in failures:
			printerr("FAIL: ", f)
		quit(1)
