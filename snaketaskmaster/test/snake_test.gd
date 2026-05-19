extends GdUnitTestSuite

const SNAKE_SCRIPT_PATH := "res://scripts/snake.gd"
const SnakeScript := preload("res://scripts/snake.gd")
const InputHandlerScript := preload("res://scripts/input_handler.gd")


func _make_snake() -> Node2D:
	var s: Node2D = auto_free(SnakeScript.new())
	add_child(s)
	return s


func _set_body(snake: Node2D, cells: Array) -> void:
	var typed: Array[Vector2i] = []
	for c in cells:
		typed.append(c)
	snake.body = typed


func test_script_file_exists() -> void:
	assert_file(SNAKE_SCRIPT_PATH).exists()


func test_initial_body_is_centered_length_3_facing_right() -> void:
	var s := _make_snake()
	var center := Vector2i(Grid.GRID_WIDTH / 2, Grid.GRID_HEIGHT / 2)
	assert_array(s.body).has_size(3)
	assert_that(s.body[0]).is_equal(center)
	assert_that(s.body[1]).is_equal(center - Vector2i(1, 0))
	assert_that(s.body[2]).is_equal(center - Vector2i(2, 0))
	assert_int(s.current_direction).is_equal(InputHandlerScript.Direction.RIGHT)
	assert_bool(s.grow_next_tick).is_false()


func test_initial_body_is_inside_interior() -> void:
	var s := _make_snake()
	for cell in s.body:
		assert_bool(Grid.is_wall(cell)).is_false()


func test_direction_to_vector_maps_all_four() -> void:
	var s := _make_snake()
	assert_that(s.direction_to_vector(InputHandlerScript.Direction.UP)).is_equal(Vector2i(0, -1))
	assert_that(s.direction_to_vector(InputHandlerScript.Direction.DOWN)).is_equal(Vector2i(0, 1))
	assert_that(s.direction_to_vector(InputHandlerScript.Direction.LEFT)).is_equal(Vector2i(-1, 0))
	assert_that(s.direction_to_vector(InputHandlerScript.Direction.RIGHT)).is_equal(Vector2i(1, 0))


func test_move_right_advances_head_and_drops_tail() -> void:
	var s := _make_snake()
	_set_body(s, [Vector2i(5, 5), Vector2i(4, 5), Vector2i(3, 5)])
	s.current_direction = InputHandlerScript.Direction.RIGHT
	s.move(InputHandlerScript.Direction.RIGHT)
	assert_array(s.body).has_size(3)
	assert_that(s.body[0]).is_equal(Vector2i(6, 5))
	assert_that(s.body[1]).is_equal(Vector2i(5, 5))
	assert_that(s.body[2]).is_equal(Vector2i(4, 5))


func test_move_each_direction_updates_head() -> void:
	var cases := [
		[InputHandlerScript.Direction.UP, Vector2i(0, -1)],
		[InputHandlerScript.Direction.DOWN, Vector2i(0, 1)],
		[InputHandlerScript.Direction.LEFT, Vector2i(-1, 0)],
		[InputHandlerScript.Direction.RIGHT, Vector2i(1, 0)],
	]
	for case in cases:
		var s := _make_snake()
		_set_body(s, [Vector2i(5, 5), Vector2i(4, 5)])
		s.move(case[0])
		assert_that(s.body[0]).is_equal(Vector2i(5, 5) + case[1])


func test_move_updates_current_direction() -> void:
	var s := _make_snake()
	_set_body(s, [Vector2i(5, 5), Vector2i(4, 5)])
	s.current_direction = InputHandlerScript.Direction.RIGHT
	s.move(InputHandlerScript.Direction.UP)
	assert_int(s.current_direction).is_equal(InputHandlerScript.Direction.UP)


func test_move_with_grow_next_tick_keeps_tail_and_clears_flag() -> void:
	var s := _make_snake()
	_set_body(s, [Vector2i(5, 5), Vector2i(4, 5), Vector2i(3, 5)])
	s.current_direction = InputHandlerScript.Direction.RIGHT
	s.grow_next_tick = true
	s.move(InputHandlerScript.Direction.RIGHT)
	assert_array(s.body).has_size(4)
	assert_that(s.body[0]).is_equal(Vector2i(6, 5))
	assert_that(s.body[1]).is_equal(Vector2i(5, 5))
	assert_that(s.body[2]).is_equal(Vector2i(4, 5))
	assert_that(s.body[3]).is_equal(Vector2i(3, 5))
	assert_bool(s.grow_next_tick).is_false()


func test_schedule_growth_sets_flag() -> void:
	var s := _make_snake()
	assert_bool(s.grow_next_tick).is_false()
	s.schedule_growth()
	assert_bool(s.grow_next_tick).is_true()


func test_grow_next_tick_resets_after_one_move() -> void:
	var s := _make_snake()
	_set_body(s, [Vector2i(5, 5), Vector2i(4, 5), Vector2i(3, 5)])
	s.current_direction = InputHandlerScript.Direction.RIGHT
	s.schedule_growth()
	s.move(InputHandlerScript.Direction.RIGHT)
	assert_array(s.body).has_size(4)
	assert_bool(s.grow_next_tick).is_false()
	s.move(InputHandlerScript.Direction.RIGHT)
	assert_array(s.body).has_size(4)
	assert_that(s.body[0]).is_equal(Vector2i(7, 5))


func test_get_head_returns_first_segment() -> void:
	var s := _make_snake()
	_set_body(s, [Vector2i(7, 8), Vector2i(6, 8)])
	assert_that(s.get_head()).is_equal(Vector2i(7, 8))


func test_perpendicular_turn_then_move() -> void:
	var s := _make_snake()
	_set_body(s, [Vector2i(5, 5), Vector2i(4, 5), Vector2i(3, 5)])
	s.current_direction = InputHandlerScript.Direction.RIGHT
	s.move(InputHandlerScript.Direction.UP)
	assert_that(s.body[0]).is_equal(Vector2i(5, 4))
	assert_that(s.body[1]).is_equal(Vector2i(5, 5))
	assert_that(s.body[2]).is_equal(Vector2i(4, 5))
	assert_int(s.current_direction).is_equal(InputHandlerScript.Direction.UP)


func test_check_collision_false_for_interior_head_no_self_overlap() -> void:
	var s := _make_snake()
	_set_body(s, [Vector2i(5, 5), Vector2i(4, 5), Vector2i(3, 5)])
	assert_bool(s.check_collision()).is_false()


func test_check_collision_true_when_head_on_left_wall() -> void:
	var s := _make_snake()
	_set_body(s, [Vector2i(0, 5), Vector2i(1, 5), Vector2i(2, 5)])
	assert_bool(s.check_collision()).is_true()


func test_check_collision_true_when_head_on_right_wall() -> void:
	var s := _make_snake()
	_set_body(s, [Vector2i(Grid.GRID_WIDTH + 1, 5), Vector2i(Grid.GRID_WIDTH, 5)])
	assert_bool(s.check_collision()).is_true()


func test_check_collision_true_when_head_on_top_wall() -> void:
	var s := _make_snake()
	_set_body(s, [Vector2i(5, 0), Vector2i(5, 1)])
	assert_bool(s.check_collision()).is_true()


func test_check_collision_true_when_head_on_bottom_wall() -> void:
	var s := _make_snake()
	_set_body(s, [Vector2i(5, Grid.GRID_HEIGHT + 1), Vector2i(5, Grid.GRID_HEIGHT)])
	assert_bool(s.check_collision()).is_true()


func test_check_collision_true_when_head_overlaps_body_segment() -> void:
	var s := _make_snake()
	# Snake curls back on itself: head occupies same cell as segments[3]
	_set_body(s, [
		Vector2i(5, 5),
		Vector2i(5, 6),
		Vector2i(6, 6),
		Vector2i(6, 5),
		Vector2i(5, 5),  # head collides here
	])
	assert_bool(s.check_collision()).is_true()


func test_check_collision_false_for_single_segment_snake() -> void:
	# Head-only snake (no body to self-collide with), in interior.
	var s := _make_snake()
	_set_body(s, [Vector2i(5, 5)])
	assert_bool(s.check_collision()).is_false()


func test_check_collision_after_move_into_wall() -> void:
	# Drive snake into the right wall via move() and verify collision detected.
	var s := _make_snake()
	_set_body(s, [Vector2i(Grid.GRID_WIDTH, 5), Vector2i(Grid.GRID_WIDTH - 1, 5)])
	s.current_direction = InputHandlerScript.Direction.RIGHT
	s.move(InputHandlerScript.Direction.RIGHT)
	assert_that(s.get_head()).is_equal(Vector2i(Grid.GRID_WIDTH + 1, 5))
	assert_bool(s.check_collision()).is_true()


func test_check_collision_after_move_into_self() -> void:
	# Snake U-turns into itself. Schedule growth so segments[3] doesn't vacate
	# before the colliding tick (iter 17 lesson from prior loop).
	var s := _make_snake()
	_set_body(s, [
		Vector2i(5, 5),
		Vector2i(4, 5),
		Vector2i(4, 6),
		Vector2i(5, 6),
		Vector2i(6, 6),
		Vector2i(6, 5),  # head will collide here in 1 tick
	])
	s.current_direction = InputHandlerScript.Direction.RIGHT
	s.schedule_growth()
	s.move(InputHandlerScript.Direction.RIGHT)
	assert_that(s.get_head()).is_equal(Vector2i(6, 5))
	assert_bool(s.check_collision()).is_true()


func test_head_sprite_created_after_ready() -> void:
	var s := _make_snake()
	assert_object(s.head_sprite).is_not_null()
	assert_object(s.head_sprite).is_instanceof(Sprite2D)
	assert_object(s.head_sprite.texture).is_not_null()
	assert_object(s.head_sprite.texture).is_instanceof(Texture2D)
	# Head texture must differ from body texture (different files).
	assert_object(s.head_sprite.texture).is_not_same(load(s.BODY_TEXTURE_PATH))


func test_head_sprite_uses_head_texture_path() -> void:
	var s := _make_snake()
	var expected := load("res://source/sprites/player_head.png")
	assert_object(s.head_sprite.texture).is_same(expected)


func test_head_sprite_positioned_at_grid_center_of_body0() -> void:
	var s := _make_snake()
	var expected := Grid.grid_to_world(s.body[0])
	assert_that(s.head_sprite.position).is_equal(expected)


func test_body_sprites_pool_size_is_body_minus_one() -> void:
	var s := _make_snake()
	# Default body length 3 -> 2 body sprites.
	assert_array(s.body_sprites).has_size(s.body.size() - 1)
	for sprite in s.body_sprites:
		assert_object(sprite).is_instanceof(Sprite2D)
		assert_object(sprite.texture).is_same(load("res://source/sprites/player_body.png"))


func test_body_sprites_positioned_at_each_body_cell() -> void:
	var s := _make_snake()
	for i in range(s.body_sprites.size()):
		var expected := Grid.grid_to_world(s.body[i + 1])
		assert_that(s.body_sprites[i].position).is_equal(expected)


func test_head_sprite_position_updates_after_move() -> void:
	var s := _make_snake()
	_set_body(s, [Vector2i(5, 5), Vector2i(4, 5), Vector2i(3, 5)])
	s.current_direction = InputHandlerScript.Direction.RIGHT
	s.move(InputHandlerScript.Direction.RIGHT)
	assert_that(s.head_sprite.position).is_equal(Grid.grid_to_world(Vector2i(6, 5)))
	# Body sprites trail head along previous body cells.
	assert_that(s.body_sprites[0].position).is_equal(Grid.grid_to_world(Vector2i(5, 5)))
	assert_that(s.body_sprites[1].position).is_equal(Grid.grid_to_world(Vector2i(4, 5)))


func test_head_rotation_matches_current_direction() -> void:
	var s := _make_snake()
	_set_body(s, [Vector2i(5, 5), Vector2i(4, 5)])
	# RIGHT-facing sprite, RIGHT direction -> rotation 0.
	s.move(InputHandlerScript.Direction.RIGHT)
	assert_float(s.head_sprite.rotation).is_equal_approx(0.0, 0.0001)
	# DOWN -> +PI/2
	s.move(InputHandlerScript.Direction.DOWN)
	assert_float(s.head_sprite.rotation).is_equal_approx(PI / 2.0, 0.0001)
	# LEFT -> PI
	s.move(InputHandlerScript.Direction.LEFT)
	assert_float(absf(s.head_sprite.rotation)).is_equal_approx(PI, 0.0001)
	# UP -> -PI/2
	s.move(InputHandlerScript.Direction.UP)
	assert_float(s.head_sprite.rotation).is_equal_approx(-PI / 2.0, 0.0001)


func test_body_sprites_pool_grows_after_growth() -> void:
	var s := _make_snake()
	_set_body(s, [Vector2i(5, 5), Vector2i(4, 5), Vector2i(3, 5)])
	var initial_count: int = s.body_sprites.size()
	s.schedule_growth()
	s.move(InputHandlerScript.Direction.RIGHT)
	# Snake length 3 -> 4 after growth; body sprites should be 3.
	assert_array(s.body_sprites).has_size(initial_count + 1)
	# Each body sprite still mapped to its grid cell.
	for i in range(s.body_sprites.size()):
		assert_that(s.body_sprites[i].position).is_equal(Grid.grid_to_world(s.body[i + 1]))


func test_reset_restores_initial_centered_body_and_defaults() -> void:
	var s := _make_snake()
	_set_body(s, [Vector2i(2, 2), Vector2i(2, 3), Vector2i(2, 4), Vector2i(2, 5)])
	s.current_direction = InputHandlerScript.Direction.DOWN
	s.grow_next_tick = true
	s.reset()
	var center := Vector2i(Grid.GRID_WIDTH / 2, Grid.GRID_HEIGHT / 2)
	assert_array(s.body).has_size(3)
	assert_that(s.body[0]).is_equal(center)
	assert_that(s.body[1]).is_equal(center - Vector2i(1, 0))
	assert_that(s.body[2]).is_equal(center - Vector2i(2, 0))
	assert_int(s.current_direction).is_equal(InputHandlerScript.Direction.RIGHT)
	assert_bool(s.grow_next_tick).is_false()


func test_reset_updates_sprite_positions_and_pool_size() -> void:
	var s := _make_snake()
	_set_body(s, [Vector2i(2, 2), Vector2i(2, 3), Vector2i(2, 4), Vector2i(2, 5)])
	s.reset()
	# Body length 3 after reset -> 2 body sprites.
	assert_array(s.body_sprites).has_size(2)
	assert_that(s.head_sprite.position).is_equal(Grid.grid_to_world(s.body[0]))
	for i in range(s.body_sprites.size()):
		assert_that(s.body_sprites[i].position).is_equal(Grid.grid_to_world(s.body[i + 1]))


func test_three_consecutive_growths_extend_body_one_per_move() -> void:
	var s := _make_snake()
	_set_body(s, [Vector2i(5, 5), Vector2i(4, 5), Vector2i(3, 5)])
	s.current_direction = InputHandlerScript.Direction.RIGHT
	# Eat 3 apples back-to-back: growth must apply one segment per move.
	s.schedule_growth()
	s.move(InputHandlerScript.Direction.RIGHT)
	assert_array(s.body).has_size(4)
	s.schedule_growth()
	s.move(InputHandlerScript.Direction.RIGHT)
	assert_array(s.body).has_size(5)
	s.schedule_growth()
	s.move(InputHandlerScript.Direction.RIGHT)
	assert_array(s.body).has_size(6)
	assert_that(s.body[0]).is_equal(Vector2i(8, 5))
	assert_that(s.body[5]).is_equal(Vector2i(3, 5))
