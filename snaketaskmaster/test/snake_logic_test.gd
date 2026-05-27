extends GdUnitTestSuite

const SnakeLogicScript := preload("res://scripts/snake_logic.gd")
const GameStateScript := preload("res://scripts/game_state.gd")

const BOUNDS := Vector2i(25, 25)


# Build a GameState with an explicit snake body (head at index 0) heading Right.
func _state(snake: Array[Vector2i], dir: Vector2i = Vector2i.RIGHT) -> GameState:
	var s := GameStateScript.new()
	s.bounds = BOUNDS
	s.snake = snake
	s.direction = dir
	s.apple = GameStateScript.NO_APPLE
	s.grow_pending = 0
	s.alive = true
	s.score = 0
	return s


# --- is_valid_turn ---

func test_is_valid_turn_accepts_perpendicular_and_same_heading() -> void:
	assert_bool(SnakeLogicScript.is_valid_turn(Vector2i.RIGHT, Vector2i.UP)).is_true()
	assert_bool(SnakeLogicScript.is_valid_turn(Vector2i.RIGHT, Vector2i.DOWN)).is_true()
	assert_bool(SnakeLogicScript.is_valid_turn(Vector2i.RIGHT, Vector2i.RIGHT)).is_true()


func test_is_valid_turn_rejects_180_reversal() -> void:
	assert_bool(SnakeLogicScript.is_valid_turn(Vector2i.RIGHT, Vector2i.LEFT)).is_false()
	assert_bool(SnakeLogicScript.is_valid_turn(Vector2i.UP, Vector2i.DOWN)).is_false()


func test_is_valid_turn_rejects_zero_and_non_cardinal() -> void:
	assert_bool(SnakeLogicScript.is_valid_turn(Vector2i.RIGHT, Vector2i.ZERO)).is_false()
	assert_bool(SnakeLogicScript.is_valid_turn(Vector2i.RIGHT, Vector2i(1, 1))).is_false()
	assert_bool(SnakeLogicScript.is_valid_turn(Vector2i.RIGHT, Vector2i(2, 0))).is_false()


# --- next_head ---

func test_next_head_offsets_by_direction() -> void:
	var s := _state([Vector2i(5, 5), Vector2i(4, 5)] as Array[Vector2i], Vector2i.UP)
	assert_vector(SnakeLogicScript.next_head(s)).is_equal(Vector2i(5, 4))


# --- is_lethal ---

func test_is_lethal_outside_walls() -> void:
	var s := _state([Vector2i(0, 0)] as Array[Vector2i])
	assert_bool(SnakeLogicScript.is_lethal(s, Vector2i(-1, 0))).is_true()
	assert_bool(SnakeLogicScript.is_lethal(s, Vector2i(0, -1))).is_true()
	assert_bool(SnakeLogicScript.is_lethal(s, Vector2i(BOUNDS.x, 0))).is_true()
	assert_bool(SnakeLogicScript.is_lethal(s, Vector2i(0, BOUNDS.y))).is_true()


func test_is_lethal_self_collision_on_body() -> void:
	var s := _state([Vector2i(5, 5), Vector2i(5, 6), Vector2i(6, 6), Vector2i(6, 5)] as Array[Vector2i])
	# Landing on a mid-body tile is lethal.
	assert_bool(SnakeLogicScript.is_lethal(s, Vector2i(5, 6))).is_true()


func test_is_lethal_excludes_vacating_tail_when_not_growing() -> void:
	var s := _state([Vector2i(5, 5), Vector2i(5, 6), Vector2i(6, 6), Vector2i(6, 5)] as Array[Vector2i])
	# Tail is (6,5); it vacates this tick so moving onto it is legal.
	assert_bool(SnakeLogicScript.is_lethal(s, Vector2i(6, 5))).is_false()


func test_is_lethal_tail_is_deadly_when_growing() -> void:
	var s := _state([Vector2i(5, 5), Vector2i(5, 6), Vector2i(6, 6), Vector2i(6, 5)] as Array[Vector2i])
	s.grow_pending = 1   # owed a segment: tail stays put this tick
	assert_bool(SnakeLogicScript.is_lethal(s, Vector2i(6, 5))).is_true()


# --- advance ---

func test_advance_moved_shifts_body_and_preserves_length() -> void:
	var s := _state([Vector2i(5, 5), Vector2i(4, 5), Vector2i(3, 5)] as Array[Vector2i])
	var result: SnakeLogic.StepResult = SnakeLogicScript.advance(s)
	assert_int(result).is_equal(SnakeLogicScript.StepResult.MOVED)
	assert_array(s.snake).has_size(3)
	assert_vector(s.snake[0]).is_equal(Vector2i(6, 5))   # new head
	assert_vector(s.snake[2]).is_equal(Vector2i(4, 5))   # old tail popped
	assert_bool(s.alive).is_true()


func test_advance_ate_grows_scores_and_clears_apple() -> void:
	var s := _state([Vector2i(5, 5), Vector2i(4, 5), Vector2i(3, 5)] as Array[Vector2i])
	s.apple = Vector2i(6, 5)   # directly ahead
	var result: SnakeLogic.StepResult = SnakeLogicScript.advance(s)
	assert_int(result).is_equal(SnakeLogicScript.StepResult.ATE)
	assert_int(s.score).is_equal(1)
	assert_array(s.snake).has_size(4)   # grew by one immediately
	assert_vector(s.snake[0]).is_equal(Vector2i(6, 5))
	assert_vector(s.apple).is_equal(GameStateScript.NO_APPLE)
	assert_int(s.grow_pending).is_equal(0)   # owed segment consumed this tick


func test_advance_died_on_wall_sets_alive_false_and_leaves_snake() -> void:
	var s := _state([Vector2i(24, 5), Vector2i(23, 5), Vector2i(22, 5)] as Array[Vector2i])
	var result: SnakeLogic.StepResult = SnakeLogicScript.advance(s)
	assert_int(result).is_equal(SnakeLogicScript.StepResult.DIED)
	assert_bool(s.alive).is_false()
	assert_array(s.snake).has_size(3)   # untouched on death


func test_advance_chasing_vacating_tail_is_legal() -> void:
	# Snake curled so the next head lands on the current tail tile, which vacates.
	# Head (6,4) moving DOWN onto tail (6,5).
	var s := _state([Vector2i(6, 4), Vector2i(5, 4), Vector2i(5, 5), Vector2i(6, 5)] as Array[Vector2i], Vector2i.DOWN)
	var result: SnakeLogic.StepResult = SnakeLogicScript.advance(s)
	assert_int(result).is_equal(SnakeLogicScript.StepResult.MOVED)
	assert_bool(s.alive).is_true()
	assert_vector(s.snake[0]).is_equal(Vector2i(6, 5))
