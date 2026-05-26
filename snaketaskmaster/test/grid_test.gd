extends GdUnitTestSuite

# Grid is a global `class_name` class, referenced directly (no preload to
# avoid shadowing the global name with a const of the same name).

func test_cell_to_pixel_returns_top_left_corner() -> void:
	assert_that(Grid.cell_to_pixel(Vector2i(0, 0))).is_equal(Vector2(0, 0))
	assert_that(Grid.cell_to_pixel(Vector2i(2, 3))).is_equal(
		Vector2(2 * Grid.CELL_SIZE, 3 * Grid.CELL_SIZE))

func test_pixel_to_cell_maps_to_containing_cell() -> void:
	assert_that(Grid.pixel_to_cell(Vector2(0, 0))).is_equal(Vector2i(0, 0))
	# Exact corner of cell (2, 3).
	assert_that(Grid.pixel_to_cell(Vector2(2 * Grid.CELL_SIZE, 3 * Grid.CELL_SIZE))).is_equal(Vector2i(2, 3))
	# Anywhere inside cell (1, 1) still maps to (1, 1).
	assert_that(Grid.pixel_to_cell(Vector2(Grid.CELL_SIZE + 5, Grid.CELL_SIZE + 5))).is_equal(Vector2i(1, 1))

func test_pixel_to_cell_round_trips_with_cell_to_pixel() -> void:
	var cell := Vector2i(7, 4)
	assert_that(Grid.pixel_to_cell(Grid.cell_to_pixel(cell))).is_equal(cell)

func test_pixel_to_cell_handles_negative_positions() -> void:
	# floored division: -1px is in cell -1, not cell 0.
	assert_that(Grid.pixel_to_cell(Vector2(-1, -1))).is_equal(Vector2i(-1, -1))

func test_is_valid_cell_accepts_in_bounds() -> void:
	assert_bool(Grid.is_valid_cell(Vector2i(0, 0))).is_true()
	assert_bool(Grid.is_valid_cell(Vector2i(Grid.GRID_WIDTH - 1, Grid.GRID_HEIGHT - 1))).is_true()

func test_is_valid_cell_rejects_out_of_bounds() -> void:
	assert_bool(Grid.is_valid_cell(Vector2i(-1, 0))).is_false()
	assert_bool(Grid.is_valid_cell(Vector2i(0, -1))).is_false()
	assert_bool(Grid.is_valid_cell(Vector2i(Grid.GRID_WIDTH, 0))).is_false()
	assert_bool(Grid.is_valid_cell(Vector2i(0, Grid.GRID_HEIGHT))).is_false()

func test_is_border_cell_detects_each_edge() -> void:
	assert_bool(Grid.is_border_cell(Vector2i(0, 5))).is_true()                    # left
	assert_bool(Grid.is_border_cell(Vector2i(Grid.GRID_WIDTH - 1, 5))).is_true()  # right
	assert_bool(Grid.is_border_cell(Vector2i(5, 0))).is_true()                    # top
	assert_bool(Grid.is_border_cell(Vector2i(5, Grid.GRID_HEIGHT - 1))).is_true() # bottom

func test_is_border_cell_false_for_interior() -> void:
	assert_bool(Grid.is_border_cell(Vector2i(1, 1))).is_false()
	assert_bool(Grid.is_border_cell(Vector2i(10, 7))).is_false()
