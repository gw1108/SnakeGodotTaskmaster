extends Node


func _ready() -> void:
	var failures: Array[String] = []

	var PlayerScript: Script = load("res://scripts/player.gd")
	var p = PlayerScript.new()
	add_child(p)

	# Test 1: initial state
	if p.segments != [Vector2i(10, 7), Vector2i(9, 7), Vector2i(8, 7)]:
		failures.append("initial segments wrong: %s" % [p.segments])
	if p.current_direction != Vector2i.RIGHT:
		failures.append("initial current_direction not RIGHT: %s" % p.current_direction)
	if p.grow_pending != 0:
		failures.append("initial grow_pending not 0: %d" % p.grow_pending)
	if p.get_head_position() != Vector2i(10, 7):
		failures.append("get_head_position wrong: %s" % p.get_head_position())

	# Test 2: sprites created in _ready (head + 2 body sprites for 3 segments)
	if p._head_sprite == null:
		failures.append("head sprite not created")
	if p._body_sprites.size() != 2:
		failures.append("expected 2 body sprites, got %d" % p._body_sprites.size())
	# Head sprite positioned at grid (10,7)
	if p._head_sprite != null:
		var expected_head_px: Vector2 = GameConstants.grid_to_pixel(Vector2i(10, 7))
		if not p._head_sprite.position.is_equal_approx(expected_head_px):
			failures.append("head sprite pos %s expected %s" % [p._head_sprite.position, expected_head_px])

	# Test 3: move right — head advances, body follows, length unchanged
	p.move(Vector2i.RIGHT)
	if p.segments != [Vector2i(11, 7), Vector2i(10, 7), Vector2i(9, 7)]:
		failures.append("after move RIGHT: %s" % [p.segments])
	if p.segments.size() != 3:
		failures.append("length changed after plain move: %d" % p.segments.size())

	# Test 4: move down — perpendicular turn
	p.move(Vector2i.DOWN)
	if p.segments != [Vector2i(11, 8), Vector2i(11, 7), Vector2i(10, 7)]:
		failures.append("after move DOWN: %s" % [p.segments])
	if p.current_direction != Vector2i.DOWN:
		failures.append("current_direction not updated to DOWN: %s" % p.current_direction)

	# Test 5: add_growth then move — length grows by 1, body sprite added
	p.add_growth()
	if p.grow_pending != 1:
		failures.append("grow_pending not 1 after add_growth: %d" % p.grow_pending)
	p.move(Vector2i.DOWN)
	if p.segments.size() != 4:
		failures.append("length after growth move expected 4, got %d" % p.segments.size())
	if p.grow_pending != 0:
		failures.append("grow_pending not decremented: %d" % p.grow_pending)
	if p.segments[0] != Vector2i(11, 9):
		failures.append("head after growth move expected (11,9): %s" % p.segments[0])
	# Tail should still be the previous tail (10,7) since no shift on grow
	if p.segments[p.segments.size() - 1] != Vector2i(10, 7):
		failures.append("tail after growth wrong: %s" % p.segments[p.segments.size() - 1])
	if p._body_sprites.size() != 3:
		failures.append("body sprite count after growth expected 3, got %d" % p._body_sprites.size())

	# Test 6: occupies_position true for every segment, false otherwise
	for seg in p.segments:
		if not p.occupies_position(seg):
			failures.append("occupies_position false for segment %s" % seg)
	var empty_cell: Vector2i = Vector2i(0, 0)
	if p.occupies_position(empty_cell):
		failures.append("occupies_position true for empty cell %s" % empty_cell)

	# Test 7: multiple consecutive growth ticks compound
	p.add_growth()
	p.add_growth()
	var len_before: int = p.segments.size()
	p.move(Vector2i.LEFT)
	p.move(Vector2i.LEFT)
	if p.segments.size() != len_before + 2:
		failures.append("two growth moves expected len %d, got %d" % [len_before + 2, p.segments.size()])
	if p.grow_pending != 0:
		failures.append("grow_pending not fully consumed: %d" % p.grow_pending)

	# Test 8: head sprite position synced after moves
	if p._head_sprite != null:
		var expected_px: Vector2 = GameConstants.grid_to_pixel(p.segments[0])
		if not p._head_sprite.position.is_equal_approx(expected_px):
			failures.append("head sprite not synced: %s expected %s" % [p._head_sprite.position, expected_px])

	if failures.is_empty():
		print("OK: all Player tests passed")
		get_tree().quit(0)
	else:
		for f in failures:
			printerr("FAIL: ", f)
		get_tree().quit(1)
