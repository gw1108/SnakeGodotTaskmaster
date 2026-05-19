extends GdUnitTestSuite

func test_runner_is_alive() -> void:
	assert_int(1 + 1).is_equal(2)
	assert_str("snake").is_equal("snake")
	assert_bool(true).is_true()
