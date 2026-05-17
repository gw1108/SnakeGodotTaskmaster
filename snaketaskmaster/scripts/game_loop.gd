extends Node

signal tick
signal wall_collision
signal self_collision

@export var player: Node2D

var is_active: bool = false
var _timer: Timer


func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = GameConstants.TICK_INTERVAL
	_timer.one_shot = false
	_timer.autostart = false
	_timer.timeout.connect(_on_tick)
	add_child(_timer)


func start_game() -> void:
	is_active = true
	_timer.start()


func stop_game() -> void:
	is_active = false
	_timer.stop()


func _on_tick() -> void:
	if not is_active or player == null:
		return

	var next_dir: Vector2i = InputManager.get_buffered_direction(player.current_direction)
	player.current_direction = next_dir
	player.move(next_dir)

	var head: Vector2i = player.get_head_position()
	if not GameConstants.is_valid_grid_pos(head):
		wall_collision.emit()
		stop_game()
		return

	for i in range(1, player.segments.size()):
		if player.segments[i] == head:
			self_collision.emit()
			stop_game()
			return

	tick.emit()
