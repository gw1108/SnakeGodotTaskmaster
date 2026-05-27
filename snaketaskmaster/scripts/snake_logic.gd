class_name SnakeLogic
extends RefCounted

## Pure, stateless snake rules: movement, turning, and collision.
## Every function operates on a GameState passed by reference; the eat/move/die
## decision is reported via StepResult. No engine dependencies.

enum StepResult { MOVED, ATE, DIED }


## True if `next` is a unit cardinal direction that isn't a 180° reversal of
## `current`. Turning to keep the same heading is allowed; reversing is not.
static func is_valid_turn(current: Vector2i, next: Vector2i) -> bool:
	if absi(next.x) + absi(next.y) != 1:
		return false   # not axis-aligned / not a unit cardinal / zero
	return next != -current


## The tile the head would occupy next tick given the committed direction.
static func next_head(state: GameState) -> Vector2i:
	return state.snake[0] + state.direction


## True if moving the head to `head` would kill the snake: outside the walled
## arena, or onto a body tile. The current tail tile is excluded when nothing is
## owed (grow_pending == 0) because it vacates this same tick — the classic
## "chase your own tail end" legal move. When growing, the tail stays and is lethal.
static func is_lethal(state: GameState, head: Vector2i) -> bool:
	if head.x < 0 or head.y < 0 or head.x >= state.bounds.x or head.y >= state.bounds.y:
		return true
	var check_count := state.snake.size()
	if state.grow_pending == 0:
		check_count -= 1   # tail vacates this tick; don't count it
	for i in check_count:
		if state.snake[i] == head:
			return true
	return false


## Advance the simulation one tick, mutating `state` in place.
## DIED: lethal next head — sets alive = false, leaves the snake untouched.
## ATE:  head lands on the apple — score +1, grow this tick (skip tail-pop), apple cleared.
## MOVED: ordinary step — prepend head, pop tail (or consume an owed growth).
static func advance(state: GameState) -> StepResult:
	var head := next_head(state)
	if is_lethal(state, head):
		state.alive = false
		return StepResult.DIED

	state.snake.push_front(head)
	var result := StepResult.MOVED
	if head == state.apple:
		state.score += 1
		state.grow_pending += 1
		state.apple = GameState.NO_APPLE
		result = StepResult.ATE

	if state.grow_pending > 0:
		state.grow_pending -= 1   # consume an owed segment: skip the tail-pop
	else:
		state.snake.pop_back()

	return result
