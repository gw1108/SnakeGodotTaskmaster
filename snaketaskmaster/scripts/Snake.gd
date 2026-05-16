extends Node2D

const CELL_SIZE := 32
const GRID_WIDTH := 20
const GRID_HEIGHT := 20

const HEAD_COLOR := Color(0.2, 0.6, 0.2)
const BODY_COLOR := Color(0.4, 0.8, 0.4)
const EYE_COLOR := Color.WHITE
const PUPIL_COLOR := Color.BLACK
const CELL_PADDING := 1
const EYE_RADIUS := 3.0
const PUPIL_RADIUS := 1.5

var body: Array[Vector2i] = [Vector2i(10, 10), Vector2i(9, 10), Vector2i(8, 10)]
var heading: Vector2i = Vector2i.RIGHT
var queued_heading: Vector2i = Vector2i.RIGHT
var pending_growth: int = 0

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	for i in body.size():
		var cell := body[i]
		var rect := Rect2(
			cell.x * CELL_SIZE + CELL_PADDING,
			cell.y * CELL_SIZE + CELL_PADDING,
			CELL_SIZE - CELL_PADDING * 2,
			CELL_SIZE - CELL_PADDING * 2,
		)
		if i == 0:
			draw_rect(rect, HEAD_COLOR, true)
			_draw_eyes(cell)
		else:
			draw_rect(rect, BODY_COLOR, true)

func _draw_eyes(cell: Vector2i) -> void:
	# Place two eyes on the leading edge of the head, offset perpendicular to heading.
	var center := Vector2(cell.x * CELL_SIZE + CELL_SIZE * 0.5, cell.y * CELL_SIZE + CELL_SIZE * 0.5)
	var forward := Vector2(heading.x, heading.y) * (CELL_SIZE * 0.28)
	var side := Vector2(-heading.y, heading.x) * (CELL_SIZE * 0.22)
	var eye_a := center + forward + side
	var eye_b := center + forward - side
	draw_circle(eye_a, EYE_RADIUS, EYE_COLOR)
	draw_circle(eye_b, EYE_RADIUS, EYE_COLOR)
	draw_circle(eye_a, PUPIL_RADIUS, PUPIL_COLOR)
	draw_circle(eye_b, PUPIL_RADIUS, PUPIL_COLOR)

func queue_direction(new_direction: Vector2i) -> void:
	# Reject 180° reversal against the *current* heading (locked once per tick).
	if new_direction + heading == Vector2i.ZERO:
		return
	queued_heading = new_direction

func move() -> void:
	heading = queued_heading
	var new_head: Vector2i = body[0] + heading
	body.insert(0, new_head)
	if pending_growth > 0:
		pending_growth -= 1
	else:
		body.pop_back()
	queue_redraw()

func grow() -> void:
	pending_growth += 1

func check_collision() -> bool:
	var head := body[0]
	if head.x < 0 or head.x >= GRID_WIDTH or head.y < 0 or head.y >= GRID_HEIGHT:
		return true
	for i in range(1, body.size()):
		if head == body[i]:
			return true
	return false
