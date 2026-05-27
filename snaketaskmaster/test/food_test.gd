extends GdUnitTestSuite

func test_spawn_lands_on_interior_cell() -> void:
	var food: Food = auto_free(Food.new())
	food.spawn([] as Array[Vector2i])
	# Walls rim the perimeter, so food must stay strictly inside.
	assert_int(food.grid_pos.x).is_greater(0)
	assert_int(food.grid_pos.x).is_less(Grid.GRID_WIDTH - 1)
	assert_int(food.grid_pos.y).is_greater(0)
	assert_int(food.grid_pos.y).is_less(Grid.GRID_HEIGHT - 1)

func test_spawn_never_lands_on_snake_body() -> void:
	var food: Food = auto_free(Food.new())
	# Fill every interior column of row 7 except one open cell at (1, 7).
	var body: Array[Vector2i] = []
	for x in range(2, Grid.GRID_WIDTH - 1):
		body.append(Vector2i(x, 7))
	# Run many spawns; none may overlap the body.
	for i in range(50):
		food.spawn(body)
		assert_bool(body.has(food.grid_pos)).is_false()

func test_spawn_picks_only_remaining_cell() -> void:
	var food: Food = auto_free(Food.new())
	# Occupy every interior cell except (1, 1).
	var body: Array[Vector2i] = []
	for x in range(1, Grid.GRID_WIDTH - 1):
		for y in range(1, Grid.GRID_HEIGHT - 1):
			if Vector2i(x, y) != Vector2i(1, 1):
				body.append(Vector2i(x, y))
	food.spawn(body)
	assert_that(food.grid_pos).is_equal(Vector2i(1, 1))

func test_sprite_created_with_nearest_filter() -> void:
	# add_child runs _ready(), which builds the food sprite.
	var food: Food = auto_free(Food.new())
	add_child(food)
	assert_object(food.sprite).is_not_null()
	assert_int(food.sprite.texture_filter).is_equal(CanvasItem.TEXTURE_FILTER_NEAREST)

func test_sprite_positioned_at_cell_center() -> void:
	var food: Food = auto_free(Food.new())
	add_child(food)
	food.grid_pos = Vector2i(1, 1)
	food._process(0.0)
	# Cell (1, 1): top-left (32, 32) + half-cell (16, 16) center offset.
	assert_vector(food.sprite.position).is_equal(Vector2(48, 48))
