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
