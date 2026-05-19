extends GdUnitTestSuite

const FOOD_SCRIPT_PATH := "res://scripts/food.gd"
const FoodScript := preload("res://scripts/food.gd")


func _make_food() -> Node:
	var f: Node = auto_free(FoodScript.new())
	add_child(f)
	return f


func _to_typed(cells: Array) -> Array[Vector2i]:
	var typed: Array[Vector2i] = []
	for c in cells:
		typed.append(c)
	return typed


func test_script_file_exists() -> void:
	assert_file(FOOD_SCRIPT_PATH).exists()


func test_food_eaten_signal_is_declared() -> void:
	var f := _make_food()
	var names: Array[String] = []
	for sig in f.get_signal_list():
		names.append(sig.name)
	assert_array(names).contains(["food_eaten"])


func test_initial_position_default() -> void:
	var f := _make_food()
	assert_that(f.position).is_equal(Vector2i.ZERO)


func test_spawn_returns_true_and_places_in_interior() -> void:
	var f := _make_food()
	var ok: bool = f.spawn(_to_typed([]))
	assert_bool(ok).is_true()
	assert_bool(Grid.is_wall(f.position)).is_false()
	assert_array(Grid.get_interior_cells()).contains([f.position])


func test_spawn_avoids_occupied_cells() -> void:
	var f := _make_food()
	var occupied := Grid.get_interior_cells()
	# Leave exactly one cell free.
	var free_cell: Vector2i = occupied.pop_back()
	for _i in range(20):
		var ok: bool = f.spawn(occupied)
		assert_bool(ok).is_true()
		assert_that(f.position).is_equal(free_cell)


func test_spawn_returns_false_when_no_cells_available() -> void:
	var f := _make_food()
	var ok: bool = f.spawn(Grid.get_interior_cells())
	assert_bool(ok).is_false()


func test_spawn_does_not_place_on_any_occupied_cell() -> void:
	var f := _make_food()
	# Snake-like body occupying the center horizontal stripe.
	var occupied: Array[Vector2i] = _to_typed([
		Vector2i(5, 6), Vector2i(6, 6), Vector2i(7, 6), Vector2i(8, 6),
	])
	for _i in range(50):
		var ok: bool = f.spawn(occupied)
		assert_bool(ok).is_true()
		assert_array(occupied).not_contains([f.position])


func test_check_collision_returns_true_when_head_matches() -> void:
	var f := _make_food()
	f.position = Vector2i(4, 7)
	assert_bool(f.check_collision(Vector2i(4, 7))).is_true()


func test_check_collision_returns_false_when_head_does_not_match() -> void:
	var f := _make_food()
	f.position = Vector2i(4, 7)
	assert_bool(f.check_collision(Vector2i(5, 7))).is_false()
	assert_bool(f.check_collision(Vector2i(4, 8))).is_false()
	assert_bool(f.check_collision(Vector2i(0, 0))).is_false()


func test_check_collision_emits_food_eaten_signal_only_on_hit() -> void:
	var f := _make_food()
	f.position = Vector2i(3, 3)
	var fired: Array[int] = [0]
	f.food_eaten.connect(func(): fired[0] += 1)
	# Miss.
	f.check_collision(Vector2i(4, 3))
	assert_int(fired[0]).is_equal(0)
	# Hit.
	f.check_collision(Vector2i(3, 3))
	assert_int(fired[0]).is_equal(1)
	# Another hit increments again.
	f.check_collision(Vector2i(3, 3))
	assert_int(fired[0]).is_equal(2)


func test_spawn_can_produce_different_positions_over_many_calls() -> void:
	# Probabilistic: with 234 interior cells, 100 spawns will almost certainly
	# produce more than one unique position.
	var f := _make_food()
	var seen := {}
	for _i in range(100):
		assert_bool(f.spawn(_to_typed([]))).is_true()
		seen[f.position] = true
	assert_int(seen.size()).is_greater(1)


func test_sprite_is_created_as_child_with_food_texture() -> void:
	var f := _make_food()
	assert_object(f.sprite).is_not_null()
	assert_object(f.sprite).is_instanceof(Sprite2D)
	assert_object(f.sprite.get_parent()).is_same(f)
	assert_object(f.sprite.texture).is_same(load("res://source/sprites/food.png"))


func test_sprite_position_matches_grid_to_world_after_spawn() -> void:
	var f := _make_food()
	# Force food into a single known cell so we can assert exact position.
	var occupied := Grid.get_interior_cells()
	var target: Vector2i = occupied.pop_back()
	assert_bool(f.spawn(occupied)).is_true()
	assert_that(f.position).is_equal(target)
	assert_that(f.sprite.position).is_equal(Grid.grid_to_world(target))


func test_sprite_position_updates_on_each_successful_spawn() -> void:
	var f := _make_food()
	for _i in range(20):
		assert_bool(f.spawn(_to_typed([]))).is_true()
		assert_that(f.sprite.position).is_equal(Grid.grid_to_world(f.position))


func test_sprite_position_unchanged_when_spawn_returns_false() -> void:
	var f := _make_food()
	# First successful spawn at a known cell.
	var all_cells := Grid.get_interior_cells()
	var target: Vector2i = all_cells.pop_back()
	assert_bool(f.spawn(all_cells)).is_true()
	var locked_sprite_pos: Vector2 = f.sprite.position
	var locked_pos: Vector2i = f.position
	# Now fill ALL interior cells → spawn must return false and leave state intact.
	assert_bool(f.spawn(Grid.get_interior_cells())).is_false()
	assert_that(f.position).is_equal(locked_pos)
	assert_that(f.sprite.position).is_equal(locked_sprite_pos)
