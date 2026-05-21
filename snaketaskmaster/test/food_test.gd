extends GdUnitTestSuite

const FoodScript := preload("res://scripts/food.gd")
const ArenaScript := preload("res://scripts/arena.gd")


func _make_arena(width: int = 20, height: int = 15) -> Arena:
	var a: Arena = auto_free(ArenaScript.new())
	a.grid_width = width
	a.grid_height = height
	add_child(a)
	return a


func _make_food() -> Food:
	var f: Food = auto_free(FoodScript.new())
	add_child(f)
	return f


func test_ready_creates_sprite_with_food_texture() -> void:
	var f := _make_food()
	assert_object(f._sprite).is_not_null()
	assert_object(f._sprite.texture).is_equal(FoodScript.FOOD_TEXTURE)


func test_get_grid_pos_returns_position_grid() -> void:
	var f := _make_food()
	f.position_grid = Vector2i(7, 4)
	assert_that(f.get_grid_pos()).is_equal(Vector2i(7, 4))


func test_spawn_places_food_inside_interior_bounds() -> void:
	var arena := _make_arena()
	var f := _make_food()
	var snake_body: Array[Vector2i] = []
	for _i in range(50):
		f.spawn(arena, snake_body)
		var p := f.get_grid_pos()
		assert_int(p.x).is_greater_equal(1)
		assert_int(p.x).is_less_equal(arena.grid_width - 2)
		assert_int(p.y).is_greater_equal(1)
		assert_int(p.y).is_less_equal(arena.grid_height - 2)
		assert_bool(arena.is_wall(p)).is_false()


func test_spawn_never_lands_on_snake_body() -> void:
	var arena := _make_arena(5, 5)
	var f := _make_food()
	var snake_body: Array[Vector2i] = [Vector2i(2, 2), Vector2i(1, 2)]
	for _i in range(100):
		f.spawn(arena, snake_body)
		assert_bool(snake_body.has(f.get_grid_pos())).is_false()


func test_spawn_updates_sprite_world_position() -> void:
	var arena := _make_arena()
	var f := _make_food()
	f.spawn(arena, [] as Array[Vector2i])
	assert_that(f._sprite.position).is_equal(arena.grid_to_world(f.get_grid_pos()))


func test_spawn_randomness_visits_multiple_cells() -> void:
	var arena := _make_arena()
	var f := _make_food()
	var seen: Dictionary = {}
	for _i in range(50):
		f.spawn(arena, [] as Array[Vector2i])
		seen[f.get_grid_pos()] = true
	assert_int(seen.size()).is_greater(1)


func test_spawn_covers_only_remaining_cell_when_others_blocked() -> void:
	var arena := _make_arena(5, 5)
	var f := _make_food()
	# Interior cells in a 5x5 grid: x in [1,3], y in [1,3] -> 9 cells.
	# Block 8 of them so only (2, 2) remains.
	var snake_body: Array[Vector2i] = [
		Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1),
		Vector2i(1, 2),                 Vector2i(3, 2),
		Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3),
	]
	for _i in range(20):
		f.spawn(arena, snake_body)
		assert_that(f.get_grid_pos()).is_equal(Vector2i(2, 2))
