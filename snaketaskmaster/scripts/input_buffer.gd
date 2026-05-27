class_name InputBuffer
extends RefCounted

## A tiny FIFO of requested turns bridging async input events and synchronous
## ticks. Yields at most one legal turn per tick; validation happens at consume
## time against the last committed direction, which kills both same-frame and
## cross-frame 180° reversals.

const MAX_SIZE := 2

var _queue: Array[Vector2i] = []


## Enqueue a requested direction. Ignores an immediate duplicate of the most
## recent entry and never grows past MAX_SIZE.
func push(dir: Vector2i) -> void:
	if not _queue.is_empty() and _queue.back() == dir:
		return
	if _queue.size() >= MAX_SIZE:
		return
	_queue.append(dir)


## Pop and discard entries until one is a legal turn relative to `current_dir`,
## returning it. If no buffered entry qualifies, returns `current_dir` unchanged.
func consume(current_dir: Vector2i) -> Vector2i:
	while not _queue.is_empty():
		var candidate: Vector2i = _queue.pop_front()
		if SnakeLogic.is_valid_turn(current_dir, candidate):
			return candidate
	return current_dir


## Drop all pending turns (used on restart).
func clear() -> void:
	_queue.clear()
