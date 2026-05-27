class_name GameState
extends RefCounted

## The entire mutable state of one Snake run as plain data.
## Every logic module reads and mutates this object by reference.
## Pure data — no engine dependencies.

const NO_APPLE := Vector2i(-1, -1)

var snake: Array[Vector2i] = []   ## body tiles, head at index 0, tail last
var direction: Vector2i = Vector2i.RIGHT   ## current committed heading
var apple: Vector2i = NO_APPLE   ## apple tile, or NO_APPLE when none
var grow_pending: int = 0   ## segments still owed (skip tail-pop while > 0)
var score: int = 0   ## apples eaten this run
var alive: bool = true   ## false once a lethal collision is detected
var bounds: Vector2i = Vector2i.ZERO   ## grid dimensions, e.g. (25, 25)


## Build a fresh run: a `start_length`-tile snake near board center heading
## Right, score 0, alive, nothing owed, no apple placed yet.
static func new_game(bounds: Vector2i, start_length: int) -> GameState:
	var state := GameState.new()
	state.reset(bounds, start_length)
	return state


## Reset this object in place to the start-of-run state (used on restart so
## the same GameState is reused rather than reallocated).
func reset(p_bounds: Vector2i, start_length: int) -> void:
	bounds = p_bounds
	direction = Vector2i.RIGHT
	apple = NO_APPLE
	grow_pending = 0
	score = 0
	alive = true

	# Snake near center, head at index 0, body extending left (so it heads Right).
	var center := Vector2i(bounds.x / 2, bounds.y / 2)
	snake = []
	for i in start_length:
		snake.append(Vector2i(center.x - i, center.y))
