extends Node2D

const CELL_SIZE := 32

var body: Array[Vector2i] = [Vector2i(10, 10), Vector2i(9, 10), Vector2i(8, 10)]
var heading: Vector2i = Vector2i.RIGHT
var queued_heading: Vector2i = Vector2i.RIGHT

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	for i in body.size():
		var cell := body[i]
		var color := Color.GREEN if i == 0 else Color.LIME_GREEN
		draw_rect(Rect2(cell.x * CELL_SIZE, cell.y * CELL_SIZE, CELL_SIZE, CELL_SIZE), color, true)

func queue_direction(new_direction: Vector2i) -> void:
	# Reject 180° reversal against the *current* heading (locked once per tick).
	if new_direction + heading == Vector2i.ZERO:
		return
	queued_heading = new_direction

func move() -> void:
	heading = queued_heading
	var new_head: Vector2i = body[0] + heading
	body.insert(0, new_head)
	body.pop_back()
	queue_redraw()
