extends GdUnitTestSuite

func test_initial_body_is_length_three() -> void:
	var snake: Snake = auto_free(Snake.new())
	assert_int(snake.body.size()).is_equal(3)
	assert_that(snake.get_head()).is_equal(Vector2i(10, 7))

func test_move_advances_head_in_direction() -> void:
	var snake: Snake = auto_free(Snake.new())
	snake.move()
	assert_that(snake.get_head()).is_equal(Vector2i(11, 7))

func test_move_keeps_length_constant() -> void:
	var snake: Snake = auto_free(Snake.new())
	snake.move()
	assert_int(snake.body.size()).is_equal(3)

func test_move_drops_tail() -> void:
	var snake: Snake = auto_free(Snake.new())
	snake.move()
	# The old tail cell (8, 7) should no longer be present.
	assert_bool(snake.body.has(Vector2i(8, 7))).is_false()

func test_grow_increases_length_by_one_on_next_move() -> void:
	var snake: Snake = auto_free(Snake.new())
	snake.grow()
	snake.move()
	assert_int(snake.body.size()).is_equal(4)

func test_grow_only_applies_once_per_call() -> void:
	var snake: Snake = auto_free(Snake.new())
	snake.grow()
	snake.move()
	snake.move()
	assert_int(snake.body.size()).is_equal(4)

func test_direction_change_is_followed() -> void:
	var snake: Snake = auto_free(Snake.new())
	snake.direction = Vector2i.DOWN
	snake.move()
	assert_that(snake.get_head()).is_equal(Vector2i(10, 8))

func test_set_direction_accepts_perpendicular_turn() -> void:
	var snake: Snake = auto_free(Snake.new())
	# Default direction is RIGHT; turning UP is perpendicular and allowed.
	snake.set_direction(Vector2i.UP)
	assert_that(snake.direction).is_equal(Vector2i.UP)

func test_set_direction_rejects_180_reversal() -> void:
	var snake: Snake = auto_free(Snake.new())
	# Default direction is RIGHT; LEFT would fold into the neck and is ignored.
	snake.set_direction(Vector2i.LEFT)
	assert_that(snake.direction).is_equal(Vector2i.RIGHT)

func test_set_direction_ignores_zero_vector() -> void:
	var snake: Snake = auto_free(Snake.new())
	snake.set_direction(Vector2i.ZERO)
	assert_that(snake.direction).is_equal(Vector2i.RIGHT)

func test_check_self_collision_detects_overlap() -> void:
	var snake: Snake = auto_free(Snake.new())
	snake.body = [Vector2i(5, 5), Vector2i(6, 5), Vector2i(5, 5)]
	assert_bool(snake.check_self_collision()).is_true()

func test_check_self_collision_false_when_clear() -> void:
	var snake: Snake = auto_free(Snake.new())
	assert_bool(snake.check_self_collision()).is_false()

func test_head_sprite_created_with_nearest_filter() -> void:
	# add_child runs _ready(), which builds the head sprite.
	var snake: Snake = auto_free(Snake.new())
	add_child(snake)
	assert_object(snake.head_sprite).is_not_null()
	assert_int(snake.head_sprite.texture_filter).is_equal(CanvasItem.TEXTURE_FILTER_NEAREST)

func test_body_sprite_pool_matches_body_minus_head() -> void:
	var snake: Snake = auto_free(Snake.new())
	add_child(snake)
	snake._process(0.0)
	assert_int(snake.body_sprites.size()).is_equal(snake.body.size() - 1)

func test_body_sprite_pool_grows_after_growth() -> void:
	var snake: Snake = auto_free(Snake.new())
	add_child(snake)
	snake.grow()
	snake.move()
	snake._process(0.0)
	assert_int(snake.body_sprites.size()).is_equal(snake.body.size() - 1)

func test_head_sprite_positioned_at_cell_center() -> void:
	var snake: Snake = auto_free(Snake.new())
	add_child(snake)
	snake._process(0.0)
	# Head at (10, 7): top-left (320, 224) + half-cell (16, 16) center offset.
	assert_vector(snake.head_sprite.position).is_equal(Vector2(336, 240))
