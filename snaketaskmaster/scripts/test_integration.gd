extends Node

# End-to-end integration test covering the full game lifecycle:
# title -> game -> game-over -> restart -> game again, with high-score
# persistence and new-high indicator across runs. Each scene is exercised
# as an instantiated child rather than via change_scene_to_file so the
# test root is never freed mid-await.

var failures: Array[String] = []


func _ready() -> void:
	# Safety auto-quit FIRST so a runtime error never zombies the process.
	get_tree().create_timer(20.0).timeout.connect(func() -> void:
		printerr("FAIL: integration test exceeded 20s safety timeout")
		get_tree().quit(2))
	await _run_tests()
	if failures.is_empty():
		print("OK: all integration tests passed")
		get_tree().quit(0)
	else:
		for f in failures:
			printerr("FAIL: ", f)
		get_tree().quit(1)


func _key_event(keycode: int) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.pressed = true
	ev.echo = false
	return ev


func _reset_world_state() -> void:
	# Don't touch high_score here -- we deliberately want it to persist
	# across simulated runs to validate that part of the contract.
	GameState.collision_type = ""
	GameState.current_score = 0
	GameState.previous_high_score = GameState.high_score
	InputManager.buffered_direction = Vector2i.ZERO


func _instantiate_title() -> CanvasLayer:
	var s: PackedScene = load("res://scenes/title_screen.tscn")
	var inst: CanvasLayer = s.instantiate()
	# Disarm guard so simulated key press doesn't change the test's scene.
	inst.game_scene_path = "res://scenes/__nonexistent_for_test.tscn"
	add_child(inst)
	return inst


func _instantiate_game() -> Node2D:
	_reset_world_state()
	var s: PackedScene = load("res://scenes/game.tscn")
	var inst: Node2D = s.instantiate()
	inst.game_over_scene_path = "res://scenes/__nonexistent_for_test.tscn"
	add_child(inst)
	return inst


func _instantiate_game_over() -> CanvasLayer:
	var s: PackedScene = load("res://scenes/game_over_screen.tscn")
	var inst: CanvasLayer = s.instantiate()
	inst.title_scene_path = "res://scenes/__nonexistent_for_test.tscn"
	add_child(inst)
	return inst


# Force the next tick to eat food: place the food cell directly in front
# of the head and zero out the input buffer so direction is unchanged.
func _force_eat_next_tick(loop: Node, pl: Node2D, fm: Node2D) -> void:
	var head: Vector2i = pl.get_head_position()
	fm.current_food_position = head + pl.current_direction
	fm.food_sprite.position = GameConstants.grid_to_pixel(fm.current_food_position)
	InputManager.buffered_direction = Vector2i.ZERO
	loop._on_tick()


func _run_tests() -> void:
	# --- Test 1: main_scene is wired to title_screen so the game actually boots ---
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene")
	if main_scene != "res://scenes/title_screen.tscn":
		failures.append("project.godot main_scene wrong: '%s'" % main_scene)

	# Reset persistent state so we start with a fresh high score for the run.
	GameState.high_score = 0
	GameState.previous_high_score = 0
	GameState.current_score = 0
	GameState.collision_type = ""

	# --- Test 2: title screen shows current high score and accepts input ---
	var title := _instantiate_title()
	await get_tree().process_frame
	var hs_label: Label = title.get_node("Control/VBoxContainer/HighScoreLabel")
	if hs_label.text != "High Score: 0":
		failures.append("title screen initial high score wrong: '%s'" % hs_label.text)
	title._input(_key_event(KEY_SPACE))
	if not title.started:
		failures.append("title screen did not set started=true on key press")
	title.queue_free()
	await get_tree().process_frame

	# --- Test 3: first full run -- eat 3 foods, hit right wall ---
	var game := _instantiate_game()
	await get_tree().process_frame
	var loop: Node = game.get_node("GameLoop")
	var pl: Node2D = game.get_node("Player")
	var fm: Node2D = game.get_node("FoodManager")
	var death_player: AudioStreamPlayer = game.get_node("DeathSound")
	var score_label: Label = game.get_node("HUD/ScoreLabel")
	# Re-seat snake mid-board so we can eat several times without hitting walls.
	pl.segments.clear()
	pl.segments.append(Vector2i(5, 7))
	pl.segments.append(Vector2i(4, 7))
	pl.segments.append(Vector2i(3, 7))
	pl.current_direction = Vector2i.RIGHT
	loop.is_active = true
	for i in range(3):
		_force_eat_next_tick(loop, pl, fm)
	if GameState.current_score != 3:
		failures.append("run1 score after 3 eats: %d (want 3)" % GameState.current_score)
	if score_label.text != "Score: 3":
		failures.append("run1 HUD lagging: '%s'" % score_label.text)
	if GameState.high_score != 3:
		failures.append("run1 high_score not tracking: %d (want 3)" % GameState.high_score)
	# Force a right-wall hit: relocate to right edge and tick.
	pl.segments.clear()
	pl.segments.append(Vector2i(GameConstants.GRID_WIDTH - 1, 7))
	pl.segments.append(Vector2i(GameConstants.GRID_WIDTH - 2, 7))
	pl.current_direction = Vector2i.RIGHT
	InputManager.buffered_direction = Vector2i.ZERO
	loop._on_tick()
	if loop.is_active:
		failures.append("run1: game_loop still active after wall hit")
	if GameState.collision_type != "wall":
		failures.append("run1: collision_type '%s' (want 'wall')" % GameState.collision_type)
	if not death_player.playing:
		failures.append("run1: DeathSound did not play after wall hit")
	# Snapshot score before navigating to game-over; it should match high_score.
	var run1_score: int = GameState.current_score
	var run1_high: int = GameState.high_score
	var run1_prev_high: int = GameState.previous_high_score
	game.queue_free()
	await get_tree().process_frame

	# --- Test 4: game-over screen reflects the run + announces new high ---
	# previous_high_score was 0 at run start, current_score is 3 => new high.
	var go := _instantiate_game_over()
	await get_tree().process_frame
	var go_score: Label = go.get_node("Control/VBoxContainer/ScoreLabel")
	var go_new_high: Label = go.get_node("Control/VBoxContainer/NewHighScoreLabel")
	var go_collide: Label = go.get_node("Control/VBoxContainer/CollisionLabel")
	if go_score.text != "Final Score: %d" % run1_score:
		failures.append("game-over score wrong: '%s'" % go_score.text)
	if not go_new_high.visible:
		failures.append("game-over: new-high banner should be visible (3 > 0)")
	if not go_collide.visible or go_collide.text != "You hit a wall":
		failures.append("game-over: wall collision label wrong: visible=%s text='%s'"
			% [go_collide.visible, go_collide.text])
	# Validate the previous_high_score snapshot logic.
	if run1_prev_high != 0:
		failures.append("run1: previous_high_score should snapshot 0 at run start, got %d" % run1_prev_high)
	if run1_high != 3:
		failures.append("run1: high_score should be 3 by game-over, got %d" % run1_high)
	# Simulate key press to "restart"; with guard injected, just verify the flag.
	go._input(_key_event(KEY_ENTER))
	if not go.restarted:
		failures.append("game-over did not set restarted=true on key press")
	go.queue_free()
	await get_tree().process_frame

	# --- Test 5: second run -- high_score persists, score resets, tie does NOT
	# show new-high banner on game-over ---
	if GameState.high_score != 3:
		failures.append("between-runs: high_score should persist as 3, got %d" % GameState.high_score)
	game = _instantiate_game()
	await get_tree().process_frame
	loop = game.get_node("GameLoop")
	pl = game.get_node("Player")
	fm = game.get_node("FoodManager")
	score_label = game.get_node("HUD/ScoreLabel")
	if GameState.current_score != 0:
		failures.append("run2: current_score not reset on new game: %d" % GameState.current_score)
	if GameState.previous_high_score != 3:
		failures.append("run2: previous_high_score should snapshot prior high=3, got %d" % GameState.previous_high_score)
	if score_label.text != "Score: 0":
		failures.append("run2: HUD did not reset: '%s'" % score_label.text)
	# Tie the previous high exactly (3 eats).
	pl.segments.clear()
	pl.segments.append(Vector2i(5, 7))
	pl.segments.append(Vector2i(4, 7))
	pl.segments.append(Vector2i(3, 7))
	pl.current_direction = Vector2i.RIGHT
	loop.is_active = true
	for i in range(3):
		_force_eat_next_tick(loop, pl, fm)
	if GameState.current_score != 3:
		failures.append("run2: score after tie: %d (want 3)" % GameState.current_score)
	if GameState.high_score != 3:
		failures.append("run2: tying should not change high_score (got %d)" % GameState.high_score)
	# Self collision: head turns down into segment then up into segment[1].
	# Use the box trick: tail pinned via add_growth so target doesn't vacate.
	pl.segments.clear()
	pl.segments.append(Vector2i(5, 5))
	pl.segments.append(Vector2i(5, 6))
	pl.segments.append(Vector2i(6, 6))
	pl.segments.append(Vector2i(6, 5))
	pl.current_direction = Vector2i.RIGHT
	pl.add_growth()
	InputManager.buffered_direction = Vector2i.ZERO
	loop._on_tick()
	if GameState.collision_type != "self":
		failures.append("run2: collision_type '%s' (want 'self')" % GameState.collision_type)
	game.queue_free()
	await get_tree().process_frame

	# --- Test 6: game-over after a tied score should NOT show new-high banner ---
	go = _instantiate_game_over()
	await get_tree().process_frame
	go_new_high = go.get_node("Control/VBoxContainer/NewHighScoreLabel")
	go_collide = go.get_node("Control/VBoxContainer/CollisionLabel")
	if go_new_high.visible:
		failures.append("tied run: new-high banner must NOT be visible (3 is not > 3)")
	if not go_collide.visible or go_collide.text != "You ran into yourself":
		failures.append("run2 game-over: self-collision label wrong: visible=%s text='%s'"
			% [go_collide.visible, go_collide.text])
	go.queue_free()
	await get_tree().process_frame

	# --- Test 7: input buffering + 180-degree block at the InputManager layer.
	# This is the contract gameplay relies on for "press a queued direction
	# before the next tick fires". ---
	game = _instantiate_game()
	await get_tree().process_frame
	loop = game.get_node("GameLoop")
	pl = game.get_node("Player")
	fm = game.get_node("FoodManager")
	pl.segments.clear()
	pl.segments.append(Vector2i(5, 7))
	pl.segments.append(Vector2i(4, 7))
	pl.segments.append(Vector2i(3, 7))
	pl.current_direction = Vector2i.RIGHT
	loop.is_active = true
	# Move food well out of the way so it doesn't grow the snake.
	fm.current_food_position = Vector2i(0, 0)
	fm.food_sprite.position = GameConstants.grid_to_pixel(fm.current_food_position)
	# Press Down (perpendicular) -- should apply.
	InputManager._input(_key_event(KEY_DOWN))
	loop._on_tick()
	if pl.current_direction != Vector2i(0, 1):
		failures.append("input: perpendicular DOWN not applied: %s" % pl.current_direction)
	# Press Up (180 from DOWN) -- should be blocked, snake keeps moving down.
	InputManager._input(_key_event(KEY_UP))
	var head_before: Vector2i = pl.get_head_position()
	loop._on_tick()
	if pl.current_direction != Vector2i(0, 1):
		failures.append("input: 180-degree UP reversal NOT blocked: %s" % pl.current_direction)
	var head_after: Vector2i = pl.get_head_position()
	if head_after - head_before != Vector2i(0, 1):
		failures.append("input: snake should have moved DOWN after blocked reversal: delta=%s"
			% (head_after - head_before))
	# Press Left (perpendicular to DOWN) -- buffer should pick this up.
	InputManager._input(_key_event(KEY_LEFT))
	loop._on_tick()
	if pl.current_direction != Vector2i(-1, 0):
		failures.append("input: perpendicular LEFT after DOWN not applied: %s" % pl.current_direction)
	game.queue_free()
	await get_tree().process_frame

	# --- Test 8: tick cadence at production rate. Use a real timer; assert
	# we get at least floor(2.5 * interval / interval) - 1 ticks in 2.5 windows.
	# (Allow some slack for first-tick latency.) ---
	game = _instantiate_game()
	await get_tree().process_frame
	loop = game.get_node("GameLoop")
	pl = game.get_node("Player")
	# Move snake somewhere safe and aim it AWAY from walls; the cadence
	# test wraps the snake hitting walls so we relocate it.
	pl.segments.clear()
	pl.segments.append(Vector2i(10, 7))
	pl.segments.append(Vector2i(9, 7))
	pl.segments.append(Vector2i(8, 7))
	pl.current_direction = Vector2i.UP  # so it heads toward y=0, plenty of room
	InputManager.buffered_direction = Vector2i.ZERO
	# GDScript lambdas capture ints by value -- use an Array slot to mutate.
	var ticks: Array[int] = [0]
	var tick_handler := func() -> void: ticks[0] += 1
	loop.tick.connect(tick_handler)
	loop.is_active = true
	await get_tree().create_timer(GameConstants.TICK_INTERVAL * 2.5).timeout
	loop.stop_game()
	loop.tick.disconnect(tick_handler)
	# At 0.15s interval over 2.5 intervals ~= 0.375s, expect >=2 ticks.
	if ticks[0] < 2:
		failures.append("tick cadence too slow: %d ticks in 2.5x interval" % ticks[0])
	game.queue_free()
	await get_tree().process_frame
