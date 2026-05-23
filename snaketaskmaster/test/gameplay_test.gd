extends GdUnitTestSuite

const GAMEPLAY_SCENE_PATH := "res://scenes/Gameplay.tscn"


func _make_gameplay() -> Gameplay:
	var gameplay: Gameplay = auto_free(load(GAMEPLAY_SCENE_PATH).instantiate())
	add_child(gameplay)
	return gameplay


func test_initial_score_is_zero() -> void:
	var gameplay: Gameplay = _make_gameplay()
	assert_int(gameplay.score).is_equal(0)


func test_initial_hud_displays_zero() -> void:
	var gameplay: Gameplay = _make_gameplay()
	var label: Label = gameplay.hud.get_node("ScoreLabel")
	assert_str(label.text).is_equal("Score: 0")


func test_food_spawns_in_valid_cell_on_ready() -> void:
	var gameplay: Gameplay = _make_gameplay()
	var pos: Vector2i = gameplay.food.get_grid_pos()
	assert_bool(gameplay.arena.is_wall(pos)).is_false()
	assert_bool(gameplay.snake.body.has(pos)).is_false()


func test_food_eaten_signal_increments_score_and_updates_hud() -> void:
	var gameplay: Gameplay = _make_gameplay()
	gameplay.snake.food_eaten.emit()
	var label: Label = gameplay.hud.get_node("ScoreLabel")
	assert_int(gameplay.score).is_equal(1)
	assert_int(gameplay.hud.score).is_equal(1)
	assert_str(label.text).is_equal("Score: 1")


func test_food_eaten_respawns_food_in_valid_cell() -> void:
	var gameplay: Gameplay = _make_gameplay()
	gameplay.snake.food_eaten.emit()
	var pos: Vector2i = gameplay.food.get_grid_pos()
	assert_bool(gameplay.arena.is_wall(pos)).is_false()
	assert_bool(gameplay.snake.body.has(pos)).is_false()


func test_multiple_food_eaten_accumulates_score() -> void:
	var gameplay: Gameplay = _make_gameplay()
	gameplay.snake.food_eaten.emit()
	gameplay.snake.food_eaten.emit()
	gameplay.snake.food_eaten.emit()
	assert_int(gameplay.score).is_equal(3)
	assert_int(gameplay.hud.score).is_equal(3)


func test_snake_died_stops_tick_timer() -> void:
	var gameplay: Gameplay = _make_gameplay()
	gameplay.snake.died.emit()
	assert_bool(gameplay.tick_timer.is_stopped()).is_true()


func test_snake_died_starts_death_timer() -> void:
	var gameplay: Gameplay = _make_gameplay()
	gameplay.snake.died.emit()
	assert_bool(gameplay.death_timer.is_stopped()).is_false()


func test_gameplay_root_is_node2d() -> void:
	var gameplay: Gameplay = _make_gameplay()
	assert_bool(gameplay is Node2D).is_true()


func test_eat_food_audio_player_has_eat_food_stream() -> void:
	var gameplay: Gameplay = _make_gameplay()
	assert_object(gameplay.eat_food_audio_player).is_not_null()
	assert_object(gameplay.eat_food_audio_player.stream).is_not_null()
	assert_str(gameplay.eat_food_audio_player.stream.resource_path).is_equal("res://audio/eat_food.wav")


func test_food_eaten_plays_eat_food_audio() -> void:
	var gameplay: Gameplay = _make_gameplay()
	assert_bool(gameplay.eat_food_audio_player.playing).is_false()
	gameplay.snake.food_eaten.emit()
	assert_bool(gameplay.eat_food_audio_player.playing).is_true()


func test_death_audio_player_has_death_stream() -> void:
	var gameplay: Gameplay = _make_gameplay()
	assert_object(gameplay.death_audio_player).is_not_null()
	assert_object(gameplay.death_audio_player.stream).is_not_null()
	assert_str(gameplay.death_audio_player.stream.resource_path).is_equal("res://audio/death.wav")


func test_snake_died_plays_death_audio() -> void:
	var gameplay: Gameplay = _make_gameplay()
	assert_bool(gameplay.death_audio_player.playing).is_false()
	gameplay.snake.died.emit()
	assert_bool(gameplay.death_audio_player.playing).is_true()
