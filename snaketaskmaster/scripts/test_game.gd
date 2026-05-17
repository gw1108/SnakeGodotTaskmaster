extends Node


var failures: Array[String] = []


func _ready() -> void:
	# Safety auto-quit: if the await chain in _run_tests is aborted by a runtime
	# error, the trailing get_tree().quit() never fires and headless zombies.
	get_tree().create_timer(15.0).timeout.connect(func() -> void:
		printerr("FAIL: test exceeded 15s safety timeout")
		get_tree().quit(2))
	await _run_tests()
	if failures.is_empty():
		print("OK: all Game integration tests passed")
		get_tree().quit(0)
	else:
		for f in failures:
			printerr("FAIL: ", f)
		get_tree().quit(1)


func _instantiate_game() -> Node:
	GameState.reset()
	InputManager.buffered_direction = Vector2i.ZERO
	var GameScene: PackedScene = load("res://scenes/game.tscn")
	var inst := GameScene.instantiate()
	# Steer the game-over guard at a nonexistent path so triggering a
	# collision in tests doesn't actually change the scene out from under us.
	inst.game_over_scene_path = "res://scenes/__nonexistent_for_test.tscn"
	add_child(inst)
	return inst


func _run_tests() -> void:
	# Test 1: scene loads with all expected children
	var game := _instantiate_game()
	await get_tree().process_frame
	if game.get_node_or_null("Playfield") == null:
		failures.append("Playfield child missing")
	if game.get_node_or_null("Player") == null:
		failures.append("Player child missing")
	if game.get_node_or_null("FoodManager") == null:
		failures.append("FoodManager child missing")
	if game.get_node_or_null("GameLoop") == null:
		failures.append("GameLoop child missing")
	if game.get_node_or_null("HUD/ScoreLabel") == null:
		failures.append("HUD/ScoreLabel child missing")

	# Test 2: GameState reset on entry
	if GameState.current_score != 0:
		failures.append("GameState.current_score not reset: %d" % GameState.current_score)
	if GameState.collision_type != "":
		failures.append("GameState.collision_type not reset: '%s'" % GameState.collision_type)

	# Test 3: game_loop wired and active
	var loop := game.get_node("GameLoop")
	var pl := game.get_node("Player")
	var fm := game.get_node("FoodManager")
	if loop.player != pl:
		failures.append("game_loop.player not wired to Player")
	if loop.food_manager != fm:
		failures.append("game_loop.food_manager not wired to FoodManager")
	if not loop.is_active:
		failures.append("game_loop should be active after _ready")

	# Test 4: food spawned at a valid cell not overlapping snake
	var food_pos: Vector2i = fm.current_food_position
	if not GameConstants.is_valid_grid_pos(food_pos):
		failures.append("food at invalid position: %s" % food_pos)
	if pl.segments.has(food_pos):
		failures.append("food overlaps snake: %s" % food_pos)
	if fm.food_sprite == null or not fm.food_sprite.visible:
		failures.append("food sprite not visible after spawn")

	# Test 5: HUD shows initial score 0 with readable styling
	var lbl: Label = game.get_node("HUD/ScoreLabel")
	if lbl.text != "Score: 0":
		failures.append("HUD initial text wrong: '%s'" % lbl.text)
	# Contrasting font color override
	if not lbl.has_theme_color_override("font_color"):
		failures.append("ScoreLabel missing font_color override (need contrast)")
	else:
		var fc: Color = lbl.get_theme_color("font_color")
		if fc.a < 1.0:
			failures.append("ScoreLabel font_color not fully opaque: %s" % fc)
	# Readable font size
	if lbl.get_theme_font_size("font_size") < 14:
		failures.append("ScoreLabel font size too small")
	# Top-left positioning (offset_left < viewport_width/2, offset_top in top half)
	if lbl.offset_left > GameConstants.GRID_WIDTH * GameConstants.CELL_SIZE / 2:
		failures.append("ScoreLabel not in left half of screen")
	if lbl.offset_top > GameConstants.GRID_HEIGHT * GameConstants.CELL_SIZE / 2:
		failures.append("ScoreLabel not in top half of screen")
	# Semi-transparent background panel for readability
	var panel: Panel = game.get_node_or_null("HUD/ScorePanel")
	if panel == null:
		failures.append("HUD/ScorePanel missing (need semi-transparent backing)")
	else:
		if not panel.has_theme_stylebox_override("panel"):
			failures.append("ScorePanel missing stylebox override")
		else:
			var sb := panel.get_theme_stylebox("panel") as StyleBoxFlat
			if sb == null:
				failures.append("ScorePanel stylebox not StyleBoxFlat")
			elif sb.bg_color.a >= 1.0:
				failures.append("ScorePanel bg should be semi-transparent: alpha=%f" % sb.bg_color.a)
			elif sb.bg_color.a <= 0.0:
				failures.append("ScorePanel bg fully transparent (invisible)")

	# Test 6: playfield rendered as a child Node2D with tile layers
	var pf := game.get_node("Playfield")
	if pf.get_node_or_null("FloorLayer") == null:
		failures.append("Playfield/FloorLayer missing")
	if pf.get_node_or_null("WallLayer") == null:
		failures.append("Playfield/WallLayer missing")

	game.queue_free()
	await get_tree().process_frame

	# Test 7: eating food increments score and updates HUD via signal
	game = _instantiate_game()
	await get_tree().process_frame
	loop = game.get_node("GameLoop")
	pl = game.get_node("Player")
	fm = game.get_node("FoodManager")
	lbl = game.get_node("HUD/ScoreLabel")
	var head: Vector2i = pl.get_head_position()
	# Force food directly in front of head (head defaults to moving RIGHT)
	fm.current_food_position = head + Vector2i.RIGHT
	fm.food_sprite.position = GameConstants.grid_to_pixel(fm.current_food_position)
	InputManager.buffered_direction = Vector2i.ZERO
	loop._on_tick()
	if GameState.current_score != 1:
		failures.append("score did not increment after eat: %d" % GameState.current_score)
	if lbl.text != "Score: 1":
		failures.append("HUD did not refresh on eat: '%s'" % lbl.text)
	if pl.grow_pending != 1:
		failures.append("grow_pending not queued after eat: %d" % pl.grow_pending)

	# Test 7b: HUD updates in real-time across consecutive eats
	for expected in range(2, 5):
		head = pl.get_head_position()
		fm.current_food_position = head + Vector2i.RIGHT
		fm.food_sprite.position = GameConstants.grid_to_pixel(fm.current_food_position)
		InputManager.buffered_direction = Vector2i.ZERO
		loop._on_tick()
		if GameState.current_score != expected:
			failures.append("score off after %d eats: got %d" % [expected, GameState.current_score])
		if lbl.text != "Score: %d" % expected:
			failures.append("HUD lagging at eat %d: '%s'" % [expected, lbl.text])
	game.queue_free()
	await get_tree().process_frame

	# Test 8: wall collision triggers game-over flow (warning expected, no crash)
	game = _instantiate_game()
	await get_tree().process_frame
	loop = game.get_node("GameLoop")
	pl = game.get_node("Player")
	pl.segments.clear()
	pl.segments.append(Vector2i(GameConstants.GRID_WIDTH - 1, 5))
	pl.segments.append(Vector2i(GameConstants.GRID_WIDTH - 2, 5))
	pl.segments.append(Vector2i(GameConstants.GRID_WIDTH - 3, 5))
	pl.current_direction = Vector2i.RIGHT
	InputManager.buffered_direction = Vector2i.ZERO
	loop._on_tick()
	if loop.is_active:
		failures.append("game_loop still active after wall collision")
	if GameState.collision_type != "wall":
		failures.append("collision_type not 'wall': '%s'" % GameState.collision_type)
	game.queue_free()
	await get_tree().process_frame
