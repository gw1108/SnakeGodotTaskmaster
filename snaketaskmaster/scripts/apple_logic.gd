class_name AppleLogic
extends RefCounted

## Pure, stateless apple placement. Randomness is injected via a
## RandomNumberGenerator so spawns are reproducible in tests.

## Place the apple on a uniformly random tile inside `state.bounds` that the
## snake does not occupy, assign it to `state.apple`, and return it.
## Returns the sentinel Vector2i(-1, -1) (and clears the apple) when the board
## is full — the GDD's "fill the board" ceiling.
static func spawn(state: GameState, rng: RandomNumberGenerator) -> Vector2i:
	var free_cells: Array[Vector2i] = []
	for y in state.bounds.y:
		for x in state.bounds.x:
			var tile := Vector2i(x, y)
			if not state.snake.has(tile):
				free_cells.append(tile)

	if free_cells.is_empty():
		state.apple = GameState.NO_APPLE
		return GameState.NO_APPLE

	var chosen := free_cells[rng.randi_range(0, free_cells.size() - 1)]
	state.apple = chosen
	return chosen
