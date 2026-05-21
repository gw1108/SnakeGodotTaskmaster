extends GdUnitTestSuite


func before_test() -> void:
	GameState.set_score(0)


func after_test() -> void:
	GameState.set_score(0)


func test_default_score_is_zero() -> void:
	assert_int(GameState.get_score()).is_equal(0)


func test_set_score_then_get_score_round_trip() -> void:
	GameState.set_score(12)
	assert_int(GameState.get_score()).is_equal(12)


func test_set_score_overwrites_previous_value() -> void:
	GameState.set_score(5)
	GameState.set_score(9)
	assert_int(GameState.get_score()).is_equal(9)


func test_current_score_field_reflects_setter() -> void:
	GameState.set_score(3)
	assert_int(GameState.current_score).is_equal(3)
