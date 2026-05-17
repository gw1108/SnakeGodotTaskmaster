extends Node


func _ready() -> void:
	var failures: Array[String] = []
	seed(12345)

	var FoodManagerScript: Script = load("res://scripts/food_manager.gd")
	var fm = FoodManagerScript.new()
	add_child(fm)

	# Test 1: spawn_food picks a valid empty cell
	var occupied: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	var ok: bool = fm.spawn_food(occupied)
	if not ok:
		failures.append("spawn_food returned false on mostly empty grid")
	if not GameConstants.is_valid_grid_pos(fm.current_food_position):
		failures.append("food position out of bounds: %s" % fm.current_food_position)
	for cell in occupied:
		if fm.current_food_position == cell:
			failures.append("food spawned in occupied cell %s" % cell)

	# Test 2: sprite present, positioned at grid_to_pixel, and visible
	if fm.food_sprite == null:
		failures.append("food_sprite is null after spawn")
	else:
		var expected_px: Vector2 = GameConstants.grid_to_pixel(fm.current_food_position)
		if not fm.food_sprite.position.is_equal_approx(expected_px):
			failures.append("food_sprite at %s expected %s" % [fm.food_sprite.position, expected_px])
		if not fm.food_sprite.visible:
			failures.append("food_sprite not visible after spawn")

	# Test 3: check_collision at food position returns true and emits signal
	var emitted := [false]
	fm.food_eaten.connect(func(): emitted[0] = true)
	if not fm.check_collision(fm.current_food_position):
		failures.append("check_collision should return true at food position")
	if not emitted[0]:
		failures.append("food_eaten signal not emitted on collision")

	# Test 4: check_collision at non-food position returns false, no signal
	emitted[0] = false
	var off: Vector2i = fm.current_food_position + Vector2i(1, 1)
	if not GameConstants.is_valid_grid_pos(off) or off == fm.current_food_position:
		off = Vector2i(0, 0) if fm.current_food_position != Vector2i(0, 0) else Vector2i(1, 0)
	if fm.check_collision(off):
		failures.append("check_collision should return false at non-food cell %s" % off)
	if emitted[0]:
		failures.append("food_eaten signal emitted at non-food cell")

	# Test 5: spawn_food on near-full grid picks the only empty cell
	var only_empty := Vector2i(5, 5)
	var near_full: Array[Vector2i] = []
	for x in range(GameConstants.GRID_WIDTH):
		for y in range(GameConstants.GRID_HEIGHT):
			var c := Vector2i(x, y)
			if c != only_empty:
				near_full.append(c)
	if not fm.spawn_food(near_full):
		failures.append("spawn_food on near-full grid returned false")
	if fm.current_food_position != only_empty:
		failures.append("spawn_food on near-full grid expected (5,5) got %s" % fm.current_food_position)

	# Test 6: spawn_food on fully occupied grid returns false, position unchanged
	var prev_pos: Vector2i = fm.current_food_position
	var full_grid: Array[Vector2i] = []
	for x in range(GameConstants.GRID_WIDTH):
		for y in range(GameConstants.GRID_HEIGHT):
			full_grid.append(Vector2i(x, y))
	if fm.spawn_food(full_grid):
		failures.append("spawn_food on full grid should return false")
	if fm.current_food_position != prev_pos:
		failures.append("current_food_position changed despite failed spawn")

	if failures.is_empty():
		print("OK: all FoodManager tests passed")
		get_tree().quit(0)
	else:
		for f in failures:
			printerr("FAIL: ", f)
		get_tree().quit(1)
