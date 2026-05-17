extends Node


func _ready() -> void:
	get_tree().create_timer(10.0).timeout.connect(func() -> void:
		printerr("FAIL: test exceeded 10s safety timeout")
		get_tree().quit(2))

	var TitleScene: PackedScene = load("res://scenes/title_screen.tscn")
	assert(TitleScene != null, "title_screen.tscn failed to load")

	# Test 1: scene instantiates with all required UI nodes
	var ts1 = TitleScene.instantiate()
	add_child(ts1)
	await get_tree().process_frame

	var title_label: Label = ts1.get_node("Control/VBoxContainer/TitleLabel")
	var high_score_label: Label = ts1.get_node("Control/VBoxContainer/HighScoreLabel")
	var prompt_label: Label = ts1.get_node("Control/VBoxContainer/PromptLabel")

	assert(title_label != null, "TitleLabel missing")
	assert(high_score_label != null, "HighScoreLabel missing")
	assert(prompt_label != null, "PromptLabel missing")

	assert(title_label.text == "2D Grid Survival Game",
		"unexpected title text: '%s'" % title_label.text)
	assert(prompt_label.text == "Press any key to start",
		"unexpected prompt text: '%s'" % prompt_label.text)
	assert(title_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER,
		"TitleLabel not centered")
	assert(prompt_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER,
		"PromptLabel not centered")

	# Test 2: high score binds from GameState on _ready
	GameState.high_score = 0
	ts1.queue_free()
	await get_tree().process_frame

	GameState.high_score = 42
	var ts2 = TitleScene.instantiate()
	ts2.game_scene_path = "res://scenes/__nonexistent_for_test.tscn"
	add_child(ts2)
	await get_tree().process_frame
	var hs_label: Label = ts2.get_node("Control/VBoxContainer/HighScoreLabel")
	assert(hs_label.text == "High Score: 42",
		"expected 'High Score: 42', got '%s'" % hs_label.text)

	# Test 3: refresh_high_score picks up later changes
	GameState.high_score = 99
	ts2.refresh_high_score()
	assert(hs_label.text == "High Score: 99",
		"refresh_high_score did not update label, got '%s'" % hs_label.text)

	# Test 4: any key press flips started flag (game.tscn missing → guard returns)
	assert(ts2.started == false, "started should be false before input")
	var key_event := InputEventKey.new()
	key_event.keycode = KEY_SPACE
	key_event.pressed = true
	ts2._input(key_event)
	assert(ts2.started == true, "started should flip true on key press")

	# Test 5: second key press is a no-op (already started)
	var second_event := InputEventKey.new()
	second_event.keycode = KEY_ENTER
	second_event.pressed = true
	ts2._input(second_event)
	assert(ts2.started == true, "started should remain true")

	# Test 6: key release (pressed=false) does not start
	ts2.queue_free()
	await get_tree().process_frame

	GameState.high_score = 7
	var ts3 = TitleScene.instantiate()
	add_child(ts3)
	await get_tree().process_frame
	var release_event := InputEventKey.new()
	release_event.keycode = KEY_SPACE
	release_event.pressed = false
	ts3._input(release_event)
	assert(ts3.started == false, "key release should not start the game")

	# Test 7: echo key press does not start (autorepeat ignored)
	var echo_event := InputEventKey.new()
	echo_event.keycode = KEY_SPACE
	echo_event.pressed = true
	echo_event.echo = true
	ts3._input(echo_event)
	assert(ts3.started == false, "echo key press should not start the game")

	# Test 8: non-key event ignored
	var mouse_event := InputEventMouseButton.new()
	mouse_event.pressed = true
	ts3._input(mouse_event)
	assert(ts3.started == false, "mouse event should not start the game")

	# Test 9: high score persists across multiple title-screen instantiations (same session)
	ts3.queue_free()
	await get_tree().process_frame
	var ts4 = TitleScene.instantiate()
	add_child(ts4)
	await get_tree().process_frame
	var hs4: Label = ts4.get_node("Control/VBoxContainer/HighScoreLabel")
	assert(hs4.text == "High Score: 7",
		"high score should persist across instantiations, got '%s'" % hs4.text)

	print("OK: all title screen tests passed")
	get_tree().quit(0)
