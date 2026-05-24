extends GdUnitTestSuite

# ArenaRenderer builds the static floor/wall background. Tests instantiate it
# bare via .new(), add it to the tree (so _ready -> build() runs), and inspect
# the generated Sprite2D children. The build is synchronous, so no awaits.

const ArenaRendererScript := preload("res://scripts/arena_renderer.gd")

func _make_renderer() -> ArenaRenderer:
	var renderer: ArenaRenderer = auto_free(ArenaRendererScript.new())
	add_child(renderer)
	return renderer

func test_builds_one_sprite_per_grid_cell() -> void:
	var renderer := _make_renderer()
	assert_int(renderer.get_child_count()).is_equal(Grid.GRID_WIDTH * Grid.GRID_HEIGHT)

func _sprite_at(renderer: ArenaRenderer, cell: Vector2i) -> Sprite2D:
	for child in renderer.get_children():
		if child is Sprite2D and child.position == Grid.cell_to_pixel(cell):
			return child
	return null

func test_border_cells_use_wall_texture() -> void:
	var renderer := _make_renderer()
	# All four corners plus a mid-edge cell are borders.
	for cell in [
		Vector2i(0, 0),
		Vector2i(Grid.GRID_WIDTH - 1, 0),
		Vector2i(0, Grid.GRID_HEIGHT - 1),
		Vector2i(Grid.GRID_WIDTH - 1, Grid.GRID_HEIGHT - 1),
		Vector2i(Grid.GRID_WIDTH / 2, 0),
	]:
		var sprite := _sprite_at(renderer, cell)
		assert_object(sprite).is_not_null()
		assert_object(sprite.texture).is_same(ArenaRenderer.WALL_TEXTURE)

func test_interior_cells_use_floor_texture() -> void:
	var renderer := _make_renderer()
	var sprite := _sprite_at(renderer, Vector2i(Grid.GRID_WIDTH / 2, Grid.GRID_HEIGHT / 2))
	assert_object(sprite).is_not_null()
	assert_object(sprite.texture).is_same(ArenaRenderer.FLOOR_TEXTURE)

func test_sprites_are_positioned_at_cell_corners() -> void:
	var renderer := _make_renderer()
	var sprite := _sprite_at(renderer, Vector2i(3, 4))
	assert_object(sprite).is_not_null()
	assert_bool(sprite.centered).is_false()
	assert_that(sprite.position).is_equal(Grid.cell_to_pixel(Vector2i(3, 4)))

func test_rebuild_does_not_stack_duplicate_sprites() -> void:
	var renderer := _make_renderer()
	renderer.build()
	# queue_free() defers deletion to end of frame; wait one frame so the old
	# sprites are actually gone before counting.
	await get_tree().process_frame
	assert_int(renderer.get_child_count()).is_equal(Grid.GRID_WIDTH * Grid.GRID_HEIGHT)
