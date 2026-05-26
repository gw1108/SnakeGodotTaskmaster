extends GdUnitTestSuite

func test_grid_to_world_origin() -> void:
	assert_that(Grid.grid_to_world(Vector2i(0, 0))).is_equal(Vector2(0, 0))

func test_grid_to_world_scales_by_cell_size() -> void:
	assert_that(Grid.grid_to_world(Vector2i(3, 2))) \
		.is_equal(Vector2(3 * Grid.CELL_SIZE, 2 * Grid.CELL_SIZE))

func test_world_to_grid_floors_into_cell() -> void:
	# Any world point inside a cell maps back to that cell's coordinate.
	assert_that(Grid.world_to_grid(Vector2(Grid.CELL_SIZE + 5, 5))).is_equal(Vector2i(1, 0))

func test_round_trip_grid_world_grid() -> void:
	var cell := Vector2i(4, 7)
	assert_that(Grid.world_to_grid(Grid.grid_to_world(cell))).is_equal(cell)

func test_is_in_bounds_accepts_corners() -> void:
	assert_bool(Grid.is_in_bounds(Vector2i(0, 0))).is_true()
	assert_bool(Grid.is_in_bounds(Vector2i(Grid.GRID_WIDTH - 1, Grid.GRID_HEIGHT - 1))).is_true()

func test_is_in_bounds_rejects_out_of_range() -> void:
	assert_bool(Grid.is_in_bounds(Vector2i(-1, 0))).is_false()
	assert_bool(Grid.is_in_bounds(Vector2i(0, -1))).is_false()
	assert_bool(Grid.is_in_bounds(Vector2i(Grid.GRID_WIDTH, 0))).is_false()
	assert_bool(Grid.is_in_bounds(Vector2i(0, Grid.GRID_HEIGHT))).is_false()
