extends GdUnitTestSuite

const GAME_TICK_SCENE_PATH := "res://scenes/game_tick.tscn"
const GAME_TICK_SCRIPT_PATH := "res://scripts/game_tick.gd"


func _make_game_tick() -> Node:
	var packed := load(GAME_TICK_SCENE_PATH) as PackedScene
	var inst: Node = auto_free(packed.instantiate())
	add_child(inst)
	return inst


func test_scene_file_exists() -> void:
	assert_file(GAME_TICK_SCENE_PATH).exists()
	assert_file(GAME_TICK_SCRIPT_PATH).exists()


func test_tick_rate_constant() -> void:
	var script := load(GAME_TICK_SCRIPT_PATH) as GDScript
	assert_object(script).is_not_null()
	assert_float(script.get_script_constant_map()["TICK_RATE"]).is_equal_approx(0.15, 0.0001)


func test_instance_has_timer_child_configured() -> void:
	var gt := _make_game_tick()
	var timer := gt.get_node_or_null("Timer") as Timer
	assert_object(timer).is_not_null()
	assert_object(timer).is_instanceof(Timer)
	assert_float(timer.wait_time).is_equal_approx(0.15, 0.0001)
	assert_bool(timer.one_shot).is_false()
	assert_bool(timer.autostart).is_false()


func test_signal_tick_occurred_declared() -> void:
	var gt := _make_game_tick()
	var found := false
	for s in gt.get_signal_list():
		if s["name"] == "tick_occurred":
			found = true
			break
	assert_bool(found).is_true()


func test_does_not_emit_before_start() -> void:
	var gt := _make_game_tick()
	var fired: Array[int] = [0]
	gt.tick_occurred.connect(func() -> void: fired[0] += 1)
	await get_tree().create_timer(0.3).timeout
	assert_int(fired[0]).is_equal(0)
	assert_bool(gt.is_running()).is_false()


func test_start_tick_begins_emission() -> void:
	var gt := _make_game_tick()
	var fired: Array[int] = [0]
	gt.tick_occurred.connect(func() -> void: fired[0] += 1)
	gt.start_tick()
	assert_bool(gt.is_running()).is_true()
	# Wait 2.5 * TICK_RATE = 0.375s, expect at least 2 ticks
	await get_tree().create_timer(0.4).timeout
	assert_int(fired[0]).is_greater_equal(2)


func test_stop_tick_halts_emission() -> void:
	var gt := _make_game_tick()
	var fired: Array[int] = [0]
	gt.tick_occurred.connect(func() -> void: fired[0] += 1)
	gt.start_tick()
	await get_tree().create_timer(0.2).timeout
	gt.stop_tick()
	assert_bool(gt.is_running()).is_false()
	var snapshot := fired[0]
	await get_tree().create_timer(0.3).timeout
	# No additional ticks after stop
	assert_int(fired[0]).is_equal(snapshot)


func test_restart_after_stop() -> void:
	var gt := _make_game_tick()
	var fired: Array[int] = [0]
	gt.tick_occurred.connect(func() -> void: fired[0] += 1)
	gt.start_tick()
	await get_tree().create_timer(0.2).timeout
	gt.stop_tick()
	var snapshot := fired[0]
	gt.start_tick()
	await get_tree().create_timer(0.4).timeout
	assert_int(fired[0]).is_greater(snapshot)


func test_game_scene_contains_game_tick_instance() -> void:
	var packed := load("res://scenes/game.tscn") as PackedScene
	var game: Node2D = auto_free(packed.instantiate())
	add_child(game)
	var gt := game.get_node_or_null("GameTick")
	assert_object(gt).is_not_null()
	var timer := gt.get_node_or_null("Timer") as Timer
	assert_object(timer).is_not_null()
	assert_float(timer.wait_time).is_equal_approx(0.15, 0.0001)
