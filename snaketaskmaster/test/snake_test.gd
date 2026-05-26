extends GdUnitTestSuite

# Snake is a global `class_name` class, referenced directly (no preload to
# avoid shadowing the global name with a const of the same name).

func test_init_spawns_three_segments_at_center_facing_right() -> void:
	var snake: Snake = auto_free(Snake.new())
	var center := Vector2i(Grid.GRID_WIDTH / 2, Grid.GRID_HEIGHT / 2)
	assert_array(snake.body).has_size(3)
	assert_that(snake.get_head()).is_equal(center)
	assert_that(snake.body[1]).is_equal(center - Vector2i.RIGHT)
	assert_that(snake.body[2]).is_equal(center - Vector2i.RIGHT * 2)
	assert_that(snake.direction).is_equal(Vector2i.RIGHT)

func test_move_forward_advances_head_and_keeps_length() -> void:
	var snake: Snake = auto_free(Snake.new())
	var old_head: Vector2i = snake.get_head()
	snake.move_forward()
	assert_that(snake.get_head()).is_equal(old_head + Vector2i.RIGHT)
	assert_array(snake.body).has_size(3)

func test_move_forward_follows_current_direction() -> void:
	var snake: Snake = auto_free(Snake.new())
	snake.set_direction(Vector2i.UP)
	var old_head: Vector2i = snake.get_head()
	snake.move_forward()
	assert_that(snake.get_head()).is_equal(old_head + Vector2i.UP)

func test_grow_adds_head_without_removing_tail() -> void:
	var snake: Snake = auto_free(Snake.new())
	var old_head: Vector2i = snake.get_head()
	var old_tail: Vector2i = snake.body[-1]
	snake.grow()
	assert_array(snake.body).has_size(4)
	assert_that(snake.get_head()).is_equal(old_head + Vector2i.RIGHT)
	assert_that(snake.body[-1]).is_equal(old_tail)

func test_set_direction_changes_direction() -> void:
	var snake: Snake = auto_free(Snake.new())
	snake.set_direction(Vector2i.DOWN)
	assert_that(snake.direction).is_equal(Vector2i.DOWN)

func test_set_direction_rejects_180_reversal_when_longer_than_one() -> void:
	var snake: Snake = auto_free(Snake.new())
	# Facing RIGHT with 3 segments: LEFT is a 180 reversal and must be ignored.
	snake.set_direction(Vector2i.LEFT)
	assert_that(snake.direction).is_equal(Vector2i.RIGHT)

func test_set_direction_allows_reversal_when_single_segment() -> void:
	var snake: Snake = auto_free(Snake.new())
	snake.body = [Vector2i(5, 5)]
	snake.set_direction(Vector2i.LEFT)
	assert_that(snake.direction).is_equal(Vector2i.LEFT)

func test_is_colliding_with_self_false_when_no_overlap() -> void:
	var snake: Snake = auto_free(Snake.new())
	assert_bool(snake.is_colliding_with_self()).is_false()

func test_is_colliding_with_self_true_when_head_overlaps_body() -> void:
	var snake: Snake = auto_free(Snake.new())
	# Head shares a cell with a later segment.
	snake.body = [Vector2i(3, 3), Vector2i(4, 3), Vector2i(4, 4), Vector2i(3, 3)]
	assert_bool(snake.is_colliding_with_self()).is_true()
