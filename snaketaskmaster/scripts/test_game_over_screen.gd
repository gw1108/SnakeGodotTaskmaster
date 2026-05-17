extends Node


func _ready() -> void:
	get_tree().create_timer(10.0).timeout.connect(func() -> void:
		printerr("FAIL: test exceeded 10s safety timeout")
		get_tree().quit(2))

	var Scene: PackedScene = load("res://scenes/game_over_screen.tscn")
	assert(Scene != null, "game_over_screen.tscn failed to load")

	# --- Test 1: required UI nodes exist with expected static text/alignment ---
	GameState.current_score = 0
	GameState.previous_high_score = 0
	GameState.high_score = 0
	GameState.collision_type = ""
	var s1 = Scene.instantiate()
	s1.title_scene_path = "res://scenes/__nonexistent_for_test.tscn"
	add_child(s1)
	await get_tree().process_frame

	var title_label: Label = s1.get_node("Control/VBoxContainer/TitleLabel")
	var score_label: Label = s1.get_node("Control/VBoxContainer/ScoreLabel")
	var collision_label: Label = s1.get_node("Control/VBoxContainer/CollisionLabel")
	var new_high_label: Label = s1.get_node("Control/VBoxContainer/NewHighScoreLabel")
	var prompt_label: Label = s1.get_node("Control/VBoxContainer/PromptLabel")

	assert(title_label != null, "TitleLabel missing")
	assert(score_label != null, "ScoreLabel missing")
	assert(collision_label != null, "CollisionLabel missing")
	assert(new_high_label != null, "NewHighScoreLabel missing")
	assert(prompt_label != null, "PromptLabel missing")

	assert(title_label.text == "Game Over",
		"unexpected title text: '%s'" % title_label.text)
	assert(prompt_label.text == "Press any key to restart",
		"unexpected prompt text: '%s'" % prompt_label.text)
	assert(title_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER,
		"TitleLabel not centered")
	assert(score_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER,
		"ScoreLabel not centered")
	assert(prompt_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER,
		"PromptLabel not centered")

	# --- Test 2: score 0 / prev high 0 → no new-high banner, no collision text ---
	assert(score_label.text == "Final Score: 0",
		"expected 'Final Score: 0', got '%s'" % score_label.text)
	assert(not new_high_label.visible,
		"new-high banner should be hidden when score == prev high")
	assert(not collision_label.visible,
		"collision label should hide when collision_type is empty")

	s1.queue_free()
	await get_tree().process_frame

	# --- Test 3: final-score label binds to GameState.current_score on _ready ---
	GameState.current_score = 7
	GameState.previous_high_score = 10
	GameState.high_score = 10
	GameState.collision_type = "wall"
	var s2 = Scene.instantiate()
	s2.title_scene_path = "res://scenes/__nonexistent_for_test.tscn"
	add_child(s2)
	await get_tree().process_frame
	var sl2: Label = s2.get_node("Control/VBoxContainer/ScoreLabel")
	var nh2: Label = s2.get_node("Control/VBoxContainer/NewHighScoreLabel")
	var cl2: Label = s2.get_node("Control/VBoxContainer/CollisionLabel")
	assert(sl2.text == "Final Score: 7",
		"expected 'Final Score: 7', got '%s'" % sl2.text)
	# Score did not beat prev high (7 < 10) → no banner.
	assert(not nh2.visible, "new-high banner should hide when score < prev high")
	# Collision label visible with wall message.
	assert(cl2.visible, "collision label should show when collision_type set")
	assert(cl2.text.find("wall") >= 0 or cl2.text.to_lower().find("wall") >= 0,
		"wall collision message missing, got '%s'" % cl2.text)

	s2.queue_free()
	await get_tree().process_frame

	# --- Test 4: new-high banner shows only when current_score > previous_high_score ---
	GameState.previous_high_score = 5
	GameState.current_score = 8
	GameState.high_score = 8  # add_score() would have already bumped this during play
	GameState.collision_type = "self"
	var s3 = Scene.instantiate()
	s3.title_scene_path = "res://scenes/__nonexistent_for_test.tscn"
	add_child(s3)
	await get_tree().process_frame
	var nh3: Label = s3.get_node("Control/VBoxContainer/NewHighScoreLabel")
	var cl3: Label = s3.get_node("Control/VBoxContainer/CollisionLabel")
	assert(nh3.visible, "new-high banner should show when 8 > prev 5")
	assert(cl3.visible and cl3.text != "",
		"collision label should show 'self' message, got '%s'" % cl3.text)

	s3.queue_free()
	await get_tree().process_frame

	# --- Test 5: tied score is NOT a new high (must strictly beat) ---
	GameState.previous_high_score = 12
	GameState.current_score = 12
	GameState.high_score = 12
	GameState.collision_type = "wall"
	var s4 = Scene.instantiate()
	s4.title_scene_path = "res://scenes/__nonexistent_for_test.tscn"
	add_child(s4)
	await get_tree().process_frame
	var nh4: Label = s4.get_node("Control/VBoxContainer/NewHighScoreLabel")
	assert(not nh4.visible, "tied score should NOT trigger new-high banner")

	# --- Test 6: any key press flips restarted flag (guard returns on missing scene) ---
	assert(s4.restarted == false, "restarted should start false")
	var key_event := InputEventKey.new()
	key_event.keycode = KEY_SPACE
	key_event.pressed = true
	s4._input(key_event)
	assert(s4.restarted == true, "key press should flip restarted true")

	# --- Test 7: second key press is a no-op ---
	var second_event := InputEventKey.new()
	second_event.keycode = KEY_ENTER
	second_event.pressed = true
	s4._input(second_event)
	assert(s4.restarted == true, "second key press should be no-op")

	# --- Test 8: key release / echo / non-key events are ignored ---
	s4.queue_free()
	await get_tree().process_frame
	var s5 = Scene.instantiate()
	s5.title_scene_path = "res://scenes/__nonexistent_for_test.tscn"
	add_child(s5)
	await get_tree().process_frame

	var release_event := InputEventKey.new()
	release_event.keycode = KEY_SPACE
	release_event.pressed = false
	s5._input(release_event)
	assert(s5.restarted == false, "key release should not restart")

	var echo_event := InputEventKey.new()
	echo_event.keycode = KEY_SPACE
	echo_event.pressed = true
	echo_event.echo = true
	s5._input(echo_event)
	assert(s5.restarted == false, "echo key press should not restart")

	var mouse_event := InputEventMouseButton.new()
	mouse_event.pressed = true
	s5._input(mouse_event)
	assert(s5.restarted == false, "mouse event should not restart")

	# --- Test 9: high_score persists across instantiations (cross-scene state) ---
	s5.queue_free()
	await get_tree().process_frame
	GameState.high_score = 99
	GameState.previous_high_score = 50
	GameState.current_score = 75
	GameState.collision_type = ""
	var s6 = Scene.instantiate()
	s6.title_scene_path = "res://scenes/__nonexistent_for_test.tscn"
	add_child(s6)
	await get_tree().process_frame
	# After instantiation, GameState.high_score is unchanged (game-over screen is read-only on state).
	assert(GameState.high_score == 99,
		"game-over screen mutated high_score: %d" % GameState.high_score)
	var sl6: Label = s6.get_node("Control/VBoxContainer/ScoreLabel")
	assert(sl6.text == "Final Score: 75",
		"final score label out of sync with current_score: '%s'" % sl6.text)

	print("OK: all game-over screen tests passed")
	get_tree().quit(0)
