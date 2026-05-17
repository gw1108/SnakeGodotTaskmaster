extends Node

var buffered_direction: Vector2i = Vector2i.ZERO


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		buffered_direction = Vector2i(0, -1)
	elif event.is_action_pressed("ui_down"):
		buffered_direction = Vector2i(0, 1)
	elif event.is_action_pressed("ui_left"):
		buffered_direction = Vector2i(-1, 0)
	elif event.is_action_pressed("ui_right"):
		buffered_direction = Vector2i(1, 0)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_W:
				buffered_direction = Vector2i(0, -1)
			KEY_S:
				buffered_direction = Vector2i(0, 1)
			KEY_A:
				buffered_direction = Vector2i(-1, 0)
			KEY_D:
				buffered_direction = Vector2i(1, 0)


func get_buffered_direction(current_direction: Vector2i) -> Vector2i:
	var pending: Vector2i = buffered_direction
	buffered_direction = Vector2i.ZERO
	if pending == Vector2i.ZERO:
		return current_direction
	if pending == -current_direction:
		return current_direction
	return pending
