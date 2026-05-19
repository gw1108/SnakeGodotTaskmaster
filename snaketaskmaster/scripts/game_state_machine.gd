extends Node

enum State { PLAYING, GAME_OVER }

signal state_changed(new_state: int)

var current_state: int = State.PLAYING


func transition_to(new_state: int) -> void:
	if new_state == current_state:
		return
	_exit_state(current_state)
	current_state = new_state
	_enter_state(new_state)
	state_changed.emit(new_state)


func _enter_state(state: int) -> void:
	var tick := _get_game_tick()
	if tick == null:
		return
	match state:
		State.PLAYING:
			tick.start_tick()
		State.GAME_OVER:
			tick.stop_tick()


func _exit_state(_state: int) -> void:
	pass


func _get_game_tick() -> Node:
	var parent := get_parent()
	if parent == null:
		return null
	return parent.get_node_or_null("GameTick")
