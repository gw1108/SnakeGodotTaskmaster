extends Node


var failures: Array[String] = []


func _ready() -> void:
	get_tree().create_timer(15.0).timeout.connect(func() -> void:
		printerr("FAIL: test exceeded 15s safety timeout")
		get_tree().quit(2))
	await _run_tests()
	if failures.is_empty():
		print("OK: all food integration tests passed")
		get_tree().quit(0)
	else:
		for f in failures:
			printerr("FAIL: ", f)
		get_tree().quit(1)


func _make_loop_player_food() -> Array:
	var PlayerScript: Script = load("res://scripts/player.gd")
	var LoopScript: Script = load("res://scripts/game_loop.gd")
	var FoodScript: Script = load("res://scripts/food_manager.gd")
	var p = PlayerScript.new()
	var fm = FoodScript.new()
	var g = LoopScript.new()
	add_child(p)
	add_child(fm)
	add_child(g)
	g.player = p
	g.food_manager = fm
	return [g, p, fm]


func _run_tests() -> void:
	# Standalone GameState score helpers
	GameState.reset()
	GameState.high_score = 0
	GameState.add_score(1)
	if GameState.current_score != 1:
		failures.append("add_score(1) did not set current_score=1: got %d" % GameState.current_score)
	if GameState.high_score != 1:
		failures.append("high_score did not bump after add_score(1): got %d" % GameState.high_score)
	GameState.add_score(2)
	if GameState.current_score != 3:
		failures.append("add_score(2) cumulative wrong: got %d" % GameState.current_score)
	if GameState.high_score != 3:
		failures.append("high_score did not track current_score=3: got %d" % GameState.high_score)
	GameState.reset_score()
	if GameState.current_score != 0:
		failures.append("reset_score did not zero current_score: got %d" % GameState.current_score)
	if GameState.high_score != 3:
		failures.append("reset_score should not clear high_score: got %d" % GameState.high_score)
	GameState.add_score(1)
	if GameState.high_score != 3:
		failures.append("high_score regressed when current_score < high_score: got %d" % GameState.high_score)

	# Test 1: eating food increments score, queues growth, spawns new food
	GameState.reset()
	GameState.high_score = 0
	var trio := _make_loop_player_food()
	var g = trio[0]
	var p = trio[1]
	var fm = trio[2]
	# Place food directly in front of the player head (10,7) moving RIGHT → (11,7)
	fm.current_food_position = Vector2i(11, 7)
	fm.food_sprite.position = GameConstants.grid_to_pixel(fm.current_food_position)
	fm.food_sprite.visible = true
	p.current_direction = Vector2i.RIGHT
	InputManager.buffered_direction = Vector2i.ZERO
	var food_eaten_count: Array[int] = [0]
	g.food_eaten.connect(func(): food_eaten_count[0] += 1)
	g.start_game()
	var len_before: int = p.segments.size()
	var old_food_pos: Vector2i = fm.current_food_position
	g._on_tick()
	if GameState.current_score != 1:
		failures.append("score not incremented after eat: %d" % GameState.current_score)
	if GameState.high_score != 1:
		failures.append("high_score not raised after eat: %d" % GameState.high_score)
	if food_eaten_count[0] != 1:
		failures.append("food_eaten not emitted from game_loop: %d" % food_eaten_count[0])
	if p.grow_pending != 1:
		failures.append("grow_pending not 1 after eat: %d" % p.grow_pending)
	if fm.current_food_position == old_food_pos:
		failures.append("new food spawned at same position as eaten food: %s" % fm.current_food_position)
	if not GameConstants.is_valid_grid_pos(fm.current_food_position):
		failures.append("new food spawned out of bounds: %s" % fm.current_food_position)
	if p.segments.has(fm.current_food_position):
		failures.append("new food spawned on snake body: %s" % fm.current_food_position)
	# Next tick should consume the queued growth → length+1
	# Re-aim away from the new food / walls just to be safe.
	InputManager.buffered_direction = Vector2i.ZERO
	# Make sure the next move stays in-bounds (head is at (11,7), still RIGHT).
	# If the new food sits at (12,7) we'd re-eat; reroute around it.
	if fm.current_food_position == Vector2i(12, 7):
		InputManager.buffered_direction = Vector2i.DOWN
	g._on_tick()
	if p.segments.size() != len_before + 1:
		failures.append("length did not grow by 1 after eat+tick: got %d expected %d" % [p.segments.size(), len_before + 1])
	g.queue_free()
	p.queue_free()
	fm.queue_free()
	await get_tree().process_frame

	# Test 2: multiple consecutive eats accumulate score and length
	GameState.reset()
	GameState.high_score = 0
	trio = _make_loop_player_food()
	g = trio[0]
	p = trio[1]
	fm = trio[2]
	p.current_direction = Vector2i.RIGHT
	InputManager.buffered_direction = Vector2i.ZERO
	var initial_length: int = p.segments.size()
	# Drop food one square ahead on each of three ticks
	var eats: int = 0
	var max_eats: int = 3
	for i in range(max_eats):
		var head_now: Vector2i = p.get_head_position()
		var target: Vector2i = head_now + Vector2i.RIGHT
		# Bail if next move would leave the grid (shouldn't happen at x≤19 starting at 10).
		if not GameConstants.is_valid_grid_pos(target):
			break
		fm.current_food_position = target
		fm.food_sprite.position = GameConstants.grid_to_pixel(target)
		fm.food_sprite.visible = true
		g.start_game()
		g._on_tick()
		eats += 1
	if GameState.current_score != eats:
		failures.append("score after %d eats expected %d got %d" % [eats, eats, GameState.current_score])
	if GameState.high_score != eats:
		failures.append("high_score after %d eats expected %d got %d" % [eats, eats, GameState.high_score])
	# Each eat queues +1 growth that's consumed on the NEXT move, so after N
	# consecutive eat-ticks length == initial + (N-1) and grow_pending == 1.
	if p.segments.size() != initial_length + eats - 1:
		failures.append("length after %d eats expected %d got %d" % [eats, initial_length + eats - 1, p.segments.size()])
	if p.grow_pending != 1:
		failures.append("grow_pending after last eat expected 1 got %d" % p.grow_pending)
	# Tick once more (no food in target) to drain the queued growth.
	var post_head: Vector2i = p.get_head_position()
	var safe_target: Vector2i = post_head + Vector2i.RIGHT
	if not GameConstants.is_valid_grid_pos(safe_target):
		safe_target = post_head + Vector2i.DOWN
		InputManager.buffered_direction = Vector2i.DOWN
	fm.current_food_position = Vector2i(-1, -1)  # parked off-grid
	fm.food_sprite.visible = false
	g._on_tick()
	if p.segments.size() != initial_length + eats:
		failures.append("length after drain tick expected %d got %d" % [initial_length + eats, p.segments.size()])
	g.queue_free()
	p.queue_free()
	fm.queue_free()
	await get_tree().process_frame

	# Test 3: high_score is sticky — preserved across reset()
	GameState.reset()
	GameState.high_score = 0
	GameState.add_score(5)
	GameState.reset()
	if GameState.current_score != 0:
		failures.append("reset did not zero current_score: %d" % GameState.current_score)
	if GameState.high_score != 5:
		failures.append("reset wiped high_score: %d" % GameState.high_score)

	# Test 4: no food_manager attached → loop runs without errors and score unchanged
	GameState.reset()
	GameState.high_score = 0
	var pair_no_food := _make_loop_player_food()
	g = pair_no_food[0]
	p = pair_no_food[1]
	fm = pair_no_food[2]
	g.food_manager = null  # detach
	p.current_direction = Vector2i.RIGHT
	InputManager.buffered_direction = Vector2i.ZERO
	g.start_game()
	g._on_tick()
	if GameState.current_score != 0:
		failures.append("score changed when food_manager null: %d" % GameState.current_score)
	g.queue_free()
	p.queue_free()
	fm.queue_free()
	await get_tree().process_frame
