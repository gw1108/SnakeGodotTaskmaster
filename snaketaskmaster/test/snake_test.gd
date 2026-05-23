extends GdUnitTestSuite

const SnakeScript := preload("res://scripts/snake.gd")
const ArenaScript := preload("res://scripts/arena.gd")

const FOOD_OFFSCREEN := Vector2i(-1000, -1000)


func _make_snake() -> Snake:
	var s: Snake = auto_free(SnakeScript.new())
	add_child(s)
	return s


func _make_arena() -> Arena:
	var a: Arena = auto_free(ArenaScript.new())
	add_child(a)
	return a


func test_starts_with_starting_length() -> void:
	var s := _make_snake()
	assert_int(s.body.size()).is_equal(s.starting_length)
	assert_int(s.starting_length).is_equal(3)


func test_starts_with_head_first_and_heading_right() -> void:
	var s := _make_snake()
	assert_that(s.body[0]).is_equal(Vector2i(5, 7))
	assert_that(s.body[1]).is_equal(Vector2i(4, 7))
	assert_that(s.body[2]).is_equal(Vector2i(3, 7))
	assert_that(s.heading).is_equal(Vector2i.RIGHT)
	assert_bool(s.is_alive).is_true()


func test_queue_direction_rejects_opposite_heading() -> void:
	var s := _make_snake()
	s.queue_direction(Vector2i.LEFT)
	assert_that(s.queued_direction).is_equal(Vector2i.RIGHT)


func test_queue_direction_accepts_perpendicular() -> void:
	var s := _make_snake()
	s.queue_direction(Vector2i.UP)
	assert_that(s.queued_direction).is_equal(Vector2i.UP)


func test_tick_applies_queued_direction_to_heading() -> void:
	var s := _make_snake()
	var a := _make_arena()
	s.queue_direction(Vector2i.UP)
	s.tick(a, FOOD_OFFSCREEN)
	assert_that(s.heading).is_equal(Vector2i.UP)
	assert_that(s.body[0]).is_equal(Vector2i(5, 6))


func test_tick_advances_body_and_pops_tail() -> void:
	var s := _make_snake()
	var a := _make_arena()
	s.tick(a, FOOD_OFFSCREEN)
	assert_int(s.body.size()).is_equal(3)
	assert_that(s.body[0]).is_equal(Vector2i(6, 7))
	assert_that(s.body[1]).is_equal(Vector2i(5, 7))
	assert_that(s.body[2]).is_equal(Vector2i(4, 7))


func test_tick_into_wall_emits_died() -> void:
	var s := _make_snake()
	var a := _make_arena()
	s.body = [Vector2i(a.grid_width - 2, 7), Vector2i(a.grid_width - 3, 7), Vector2i(a.grid_width - 4, 7)] as Array[Vector2i]
	s.heading = Vector2i.RIGHT
	s.queued_direction = Vector2i.RIGHT
	var died_monitor := monitor_signals(s)
	s.tick(a, FOOD_OFFSCREEN)
	assert_bool(s.is_alive).is_false()
	await assert_signal(died_monitor).is_emitted("died")


func test_tick_into_self_emits_died() -> void:
	var s := _make_snake()
	var a := _make_arena()
	s.body = [Vector2i(5, 7), Vector2i(4, 7), Vector2i(4, 8), Vector2i(5, 8)] as Array[Vector2i]
	s.heading = Vector2i.DOWN
	s.queued_direction = Vector2i.DOWN
	var monitor := monitor_signals(s)
	s.tick(a, FOOD_OFFSCREEN)
	assert_bool(s.is_alive).is_false()
	await assert_signal(monitor).is_emitted("died")


func test_eating_food_grows_body_and_emits_food_eaten() -> void:
	var s := _make_snake()
	var a := _make_arena()
	var food_pos := Vector2i(6, 7)
	var monitor := monitor_signals(s)
	s.tick(a, food_pos)
	assert_int(s.body.size()).is_equal(4)
	assert_that(s.body[0]).is_equal(food_pos)
	assert_that(s.body[3]).is_equal(Vector2i(3, 7))
	await assert_signal(monitor).is_emitted("food_eaten")


func test_tick_after_death_is_noop() -> void:
	var s := _make_snake()
	var a := _make_arena()
	s.is_alive = false
	var before := s.body.duplicate()
	s.tick(a, FOOD_OFFSCREEN)
	assert_that(s.body).is_equal(before)


func test_update_visuals_creates_sprite_per_body_segment() -> void:
	var s := _make_snake()
	var a := _make_arena()
	s.update_visuals(a)
	assert_int(s._sprites.size()).is_equal(s.body.size())


func test_update_visuals_uses_head_texture_for_first_segment_and_body_for_rest() -> void:
	var s := _make_snake()
	var a := _make_arena()
	s.update_visuals(a)
	assert_object(s._sprites[0].texture).is_equal(SnakeScript.HEAD_TEXTURE)
	assert_object(s._sprites[1].texture).is_equal(SnakeScript.BODY_TEXTURE)
	assert_object(s._sprites[2].texture).is_equal(SnakeScript.BODY_TEXTURE)


func test_update_visuals_positions_sprites_at_arena_world_coords() -> void:
	var s := _make_snake()
	var a := _make_arena()
	s.update_visuals(a)
	for i in s.body.size():
		assert_that(s._sprites[i].position).is_equal(a.grid_to_world(s.body[i]))


func test_update_visuals_rotates_head_to_match_heading() -> void:
	var s := _make_snake()
	var a := _make_arena()
	s.heading = Vector2i.DOWN
	s.update_visuals(a)
	assert_float(s._sprites[0].rotation).is_equal_approx(PI / 2.0, 0.0001)

	s.heading = Vector2i.LEFT
	s.update_visuals(a)
	assert_float(s._sprites[0].rotation).is_equal_approx(PI, 0.0001)

	s.heading = Vector2i.UP
	s.update_visuals(a)
	assert_float(s._sprites[0].rotation).is_equal_approx(-PI / 2.0, 0.0001)

	s.heading = Vector2i.RIGHT
	s.update_visuals(a)
	assert_float(s._sprites[0].rotation).is_equal_approx(0.0, 0.0001)


func test_update_visuals_pools_sprites_on_growth_and_shrink() -> void:
	var s := _make_snake()
	var a := _make_arena()
	s.update_visuals(a)
	assert_int(s._sprites.size()).is_equal(3)
	s.body.append(Vector2i(2, 7))
	s.update_visuals(a)
	assert_int(s._sprites.size()).is_equal(4)
	s.body.pop_back()
	s.body.pop_back()
	s.update_visuals(a)
	assert_int(s._sprites.size()).is_equal(2)


func test_tick_updates_visuals_after_move() -> void:
	var s := _make_snake()
	var a := _make_arena()
	s.tick(a, FOOD_OFFSCREEN)
	assert_int(s._sprites.size()).is_equal(3)
	assert_that(s._sprites[0].position).is_equal(a.grid_to_world(Vector2i(6, 7)))


func test_heading_to_angle_maps_all_cardinals() -> void:
	assert_float(SnakeScript._heading_to_angle(Vector2i.RIGHT)).is_equal_approx(0.0, 0.0001)
	assert_float(SnakeScript._heading_to_angle(Vector2i.DOWN)).is_equal_approx(PI / 2.0, 0.0001)
	assert_float(SnakeScript._heading_to_angle(Vector2i.LEFT)).is_equal_approx(PI, 0.0001)
	assert_float(SnakeScript._heading_to_angle(Vector2i.UP)).is_equal_approx(-PI / 2.0, 0.0001)
