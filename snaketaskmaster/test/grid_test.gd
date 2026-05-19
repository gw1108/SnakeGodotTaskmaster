extends GdUnitTestSuite


func test_constants() -> void:
	assert_int(Grid.CELL_SIZE).is_equal(32)
	assert_int(Grid.GRID_WIDTH).is_equal(18)
	assert_int(Grid.GRID_HEIGHT).is_equal(13)


func test_total_dimensions_fit_viewport() -> void:
	# Total = interior + 2 wall cells per axis = 20 x 15. Cells * CELL_SIZE = 640 x 480.
	var total_width: int = (Grid.GRID_WIDTH + 2) * Grid.CELL_SIZE
	var total_height: int = (Grid.GRID_HEIGHT + 2) * Grid.CELL_SIZE
	assert_int(total_width).is_equal(640)
	assert_int(total_height).is_equal(480)


func test_grid_to_world_returns_cell_center() -> void:
	assert_that(Grid.grid_to_world(Vector2i(0, 0))).is_equal(Vector2(16, 16))
	assert_that(Grid.grid_to_world(Vector2i(1, 1))).is_equal(Vector2(48, 48))
	assert_that(Grid.grid_to_world(Vector2i(19, 14))).is_equal(Vector2(19 * 32 + 16, 14 * 32 + 16))


func test_world_to_grid_floors_into_cell() -> void:
	assert_that(Grid.world_to_grid(Vector2(0, 0))).is_equal(Vector2i(0, 0))
	assert_that(Grid.world_to_grid(Vector2(16, 16))).is_equal(Vector2i(0, 0))
	assert_that(Grid.world_to_grid(Vector2(31.9, 31.9))).is_equal(Vector2i(0, 0))
	assert_that(Grid.world_to_grid(Vector2(32, 32))).is_equal(Vector2i(1, 1))
	assert_that(Grid.world_to_grid(Vector2(48, 48))).is_equal(Vector2i(1, 1))


func test_world_and_grid_are_inverse_at_cell_centers() -> void:
	for x in range(0, Grid.GRID_WIDTH + 2):
		for y in range(0, Grid.GRID_HEIGHT + 2):
			var gp := Vector2i(x, y)
			assert_that(Grid.world_to_grid(Grid.grid_to_world(gp))).is_equal(gp)


func test_is_wall_for_border_cells() -> void:
	# Left and right wall columns
	for y in range(0, Grid.GRID_HEIGHT + 2):
		assert_bool(Grid.is_wall(Vector2i(0, y))).is_true()
		assert_bool(Grid.is_wall(Vector2i(Grid.GRID_WIDTH + 1, y))).is_true()
	# Top and bottom wall rows
	for x in range(0, Grid.GRID_WIDTH + 2):
		assert_bool(Grid.is_wall(Vector2i(x, 0))).is_true()
		assert_bool(Grid.is_wall(Vector2i(x, Grid.GRID_HEIGHT + 1))).is_true()


func test_is_wall_false_for_interior_cells() -> void:
	for x in range(1, Grid.GRID_WIDTH + 1):
		for y in range(1, Grid.GRID_HEIGHT + 1):
			assert_bool(Grid.is_wall(Vector2i(x, y))).is_false()


func test_get_interior_cells_size_and_content() -> void:
	var cells := Grid.get_interior_cells()
	assert_int(cells.size()).is_equal(Grid.GRID_WIDTH * Grid.GRID_HEIGHT)
	# Spot-check: corners of the interior
	assert_bool(cells.has(Vector2i(1, 1))).is_true()
	assert_bool(cells.has(Vector2i(Grid.GRID_WIDTH, Grid.GRID_HEIGHT))).is_true()
	# No walls included
	for c in cells:
		assert_bool(Grid.is_wall(c)).is_false()
	# Uniqueness
	var unique := {}
	for c in cells:
		unique[c] = true
	assert_int(unique.size()).is_equal(cells.size())
