extends Node


var failures: Array[String] = []
var tick_signal_count: int = 0
var wall_signal_count: int = 0
var self_signal_count: int = 0


func _ready() -> void:
	await _run_tests()
	if failures.is_empty():
		print("OK: all GameLoop tests passed")
		get_tree().quit(0)
	else:
		for f in failures:
			printerr("FAIL: ", f)
		get_tree().quit(1)


func _make_loop_with_player() -> Array:
	var PlayerScript: Script = load("res://scripts/player.gd")
	var LoopScript: Script = load("res://scripts/game_loop.gd")
	var p = PlayerScript.new()
	var g = LoopScript.new()
	add_child(p)
	add_child(g)
	g.player = p
	return [g, p]


func _run_tests() -> void:
	# Test 1: _ready creates a Timer configured per GameConstants
	var pair := _make_loop_with_player()
	var g = pair[0]
	var p = pair[1]
	if g._timer == null:
		failures.append("timer not created in _ready")
	elif not is_equal_approx(g._timer.wait_time, GameConstants.TICK_INTERVAL):
		failures.append("timer wait_time %f expected %f" % [g._timer.wait_time, GameConstants.TICK_INTERVAL])
	elif g._timer.one_shot:
		failures.append("timer should not be one_shot")
	elif g._timer.autostart:
		failures.append("timer should not autostart")
	if g.is_active:
		failures.append("is_active should default false")

	# Test 2: start_game/stop_game toggle is_active and timer running
	g.start_game()
	if not g.is_active:
		failures.append("is_active not true after start_game")
	if g._timer.is_stopped():
		failures.append("timer stopped after start_game")
	g.stop_game()
	if g.is_active:
		failures.append("is_active not false after stop_game")
	if not g._timer.is_stopped():
		failures.append("timer not stopped after stop_game")
	g.queue_free()
	p.queue_free()
	await get_tree().process_frame

	# Test 3: tick advances player one cell in current direction
	pair = _make_loop_with_player()
	g = pair[0]
	p = pair[1]
	g.tick.connect(func(): tick_signal_count += 1)
	g.start_game()
	var head_before: Vector2i = p.get_head_position()
	var dir: Vector2i = p.current_direction
	g._on_tick()
	if p.get_head_position() != head_before + dir:
		failures.append("head not advanced by direction: got %s expected %s" % [p.get_head_position(), head_before + dir])
	if tick_signal_count != 1:
		failures.append("tick signal not emitted once: %d" % tick_signal_count)
	g.queue_free()
	p.queue_free()
	await get_tree().process_frame

	# Test 4: buffered direction picked up on next tick
	pair = _make_loop_with_player()
	g = pair[0]
	p = pair[1]
	g.start_game()
	# Player starts moving RIGHT — buffer a DOWN press
	InputManager.buffered_direction = Vector2i.DOWN
	var head_pre: Vector2i = p.get_head_position()
	g._on_tick()
	if p.current_direction != Vector2i.DOWN:
		failures.append("direction not updated from buffer: %s" % p.current_direction)
	if p.get_head_position() != head_pre + Vector2i.DOWN:
		failures.append("did not move DOWN after buffered turn: %s" % p.get_head_position())
	g.queue_free()
	p.queue_free()
	await get_tree().process_frame

	# Test 5: 180° reversal blocked — keeps current direction
	pair = _make_loop_with_player()
	g = pair[0]
	p = pair[1]
	g.start_game()
	# Default direction is RIGHT; buffering LEFT should be rejected
	InputManager.buffered_direction = Vector2i.LEFT
	g._on_tick()
	if p.current_direction != Vector2i.RIGHT:
		failures.append("180° reversal not blocked: %s" % p.current_direction)
	g.queue_free()
	p.queue_free()
	await get_tree().process_frame

	# Test 6: wall collision stops loop and emits signal
	pair = _make_loop_with_player()
	g = pair[0]
	p = pair[1]
	g.wall_collision.connect(func(): wall_signal_count += 1)
	# Place head one cell from right wall, moving RIGHT
	p.segments.clear()
	p.segments.append(Vector2i(GameConstants.GRID_WIDTH - 1, 5))
	p.segments.append(Vector2i(GameConstants.GRID_WIDTH - 2, 5))
	p.segments.append(Vector2i(GameConstants.GRID_WIDTH - 3, 5))
	p.current_direction = Vector2i.RIGHT
	g.start_game()
	g._on_tick()
	if wall_signal_count != 1:
		failures.append("wall_collision not emitted: %d" % wall_signal_count)
	if g.is_active:
		failures.append("loop still active after wall collision")
	g.queue_free()
	p.queue_free()
	await get_tree().process_frame

	# Test 7: self-collision stops loop and emits signal
	pair = _make_loop_with_player()
	g = pair[0]
	p = pair[1]
	g.self_collision.connect(func(): self_signal_count += 1)
	# Construct U-turn so next move into segments[1]
	# segments: H at (5,5), then body forming a loop so moving DOWN crashes into self
	p.segments.clear()
	p.segments.append(Vector2i(5, 5))
	p.segments.append(Vector2i(5, 6))
	p.segments.append(Vector2i(6, 6))
	p.segments.append(Vector2i(6, 5))
	p.current_direction = Vector2i.LEFT
	p.add_growth()  # ensure tail does not move out of new-head cell
	g.start_game()
	# Move DOWN — new head = (5,6) which is segments[1]
	InputManager.buffered_direction = Vector2i.DOWN
	g._on_tick()
	if self_signal_count != 1:
		failures.append("self_collision not emitted: %d" % self_signal_count)
	if g.is_active:
		failures.append("loop still active after self-collision")
	g.queue_free()
	p.queue_free()
	await get_tree().process_frame

	# Test 8: timer actually fires at ~TICK_INTERVAL via tree
	pair = _make_loop_with_player()
	g = pair[0]
	p = pair[1]
	var fired: Array[int] = [0]
	g.tick.connect(func(): fired[0] += 1)
	g.start_game()
	await get_tree().create_timer(GameConstants.TICK_INTERVAL * 2.5).timeout
	g.stop_game()
	if fired[0] < 2:
		failures.append("timer did not fire at expected rate: %d in %f s" % [fired[0], GameConstants.TICK_INTERVAL * 2.5])
	g.queue_free()
	p.queue_free()
	await get_tree().process_frame

	# Test 9: _on_tick is a no-op when is_active=false
	pair = _make_loop_with_player()
	g = pair[0]
	p = pair[1]
	# Do NOT start_game — is_active stays false
	var head_pre2: Vector2i = p.get_head_position()
	g._on_tick()
	if p.get_head_position() != head_pre2:
		failures.append("tick advanced player while inactive: %s" % p.get_head_position())
	g.queue_free()
	p.queue_free()
	await get_tree().process_frame
