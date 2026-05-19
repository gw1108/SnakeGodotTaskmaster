extends Node

signal food_eaten

var position: Vector2i = Vector2i.ZERO


func spawn(occupied_cells: Array[Vector2i]) -> bool:
	var occupied := {}
	for cell in occupied_cells:
		occupied[cell] = true
	var available: Array[Vector2i] = []
	for cell in Grid.get_interior_cells():
		if not occupied.has(cell):
			available.append(cell)
	if available.is_empty():
		return false
	position = available[randi() % available.size()]
	return true


func check_collision(head_pos: Vector2i) -> bool:
	if head_pos == position:
		food_eaten.emit()
		return true
	return false
