extends GdUnitTestSuite

const InputBufferScript := preload("res://scripts/input_buffer.gd")


func test_consume_empty_returns_current_direction() -> void:
	var buf: InputBuffer = auto_free(InputBufferScript.new())
	assert_vector(buf.consume(Vector2i.RIGHT)).is_equal(Vector2i.RIGHT)


func test_consume_returns_buffered_valid_turn() -> void:
	var buf: InputBuffer = auto_free(InputBufferScript.new())
	buf.push(Vector2i.UP)
	assert_vector(buf.consume(Vector2i.RIGHT)).is_equal(Vector2i.UP)
	# Queue drained: next consume returns current.
	assert_vector(buf.consume(Vector2i.UP)).is_equal(Vector2i.UP)


func test_consume_discards_180_reversal_and_returns_current() -> void:
	var buf: InputBuffer = auto_free(InputBufferScript.new())
	buf.push(Vector2i.LEFT)   # direct reversal of RIGHT
	assert_vector(buf.consume(Vector2i.RIGHT)).is_equal(Vector2i.RIGHT)


func test_consume_one_legal_turn_per_tick_blocks_cross_frame_reversal() -> void:
	# Heading RIGHT, player buffers Up then Down within one tick.
	var buf: InputBuffer = auto_free(InputBufferScript.new())
	buf.push(Vector2i.UP)
	buf.push(Vector2i.DOWN)
	# Tick 1: consume against RIGHT -> Up is legal.
	assert_vector(buf.consume(Vector2i.RIGHT)).is_equal(Vector2i.UP)
	# Tick 2: now heading UP, the leftover Down would be a reversal -> rejected.
	assert_vector(buf.consume(Vector2i.UP)).is_equal(Vector2i.UP)


func test_push_ignores_immediate_duplicate_of_tail() -> void:
	var buf: InputBuffer = auto_free(InputBufferScript.new())
	buf.push(Vector2i.UP)
	buf.push(Vector2i.UP)   # duplicate, ignored
	buf.push(Vector2i.LEFT)
	# First consume yields Up; second yields Left (only two distinct entries stored).
	assert_vector(buf.consume(Vector2i.RIGHT)).is_equal(Vector2i.UP)
	assert_vector(buf.consume(Vector2i.UP)).is_equal(Vector2i.LEFT)


func test_push_caps_queue_at_two() -> void:
	var buf: InputBuffer = auto_free(InputBufferScript.new())
	buf.push(Vector2i.UP)
	buf.push(Vector2i.LEFT)
	buf.push(Vector2i.DOWN)   # over cap, dropped
	# Only Up and Left were stored; Down never enters.
	assert_vector(buf.consume(Vector2i.RIGHT)).is_equal(Vector2i.UP)
	assert_vector(buf.consume(Vector2i.UP)).is_equal(Vector2i.LEFT)
	assert_vector(buf.consume(Vector2i.LEFT)).is_equal(Vector2i.LEFT)   # empty -> current


func test_clear_empties_queue() -> void:
	var buf: InputBuffer = auto_free(InputBufferScript.new())
	buf.push(Vector2i.UP)
	buf.clear()
	assert_vector(buf.consume(Vector2i.RIGHT)).is_equal(Vector2i.RIGHT)
