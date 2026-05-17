extends Node

signal tick
signal wall_collision
signal self_collision
signal food_eaten

@export var player: Node2D
@export var food_manager: Node2D

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
		game_over("wall")
		return

	for i in range(1, player.segments.size()):
		if player.segments[i] == head:
			game_over("self")
			return

	if food_manager != null and food_manager.check_collision(head):
		GameState.add_score(1)
		player.add_growth()
		food_manager.spawn_food(player.segments)
		food_eaten.emit()

	tick.emit()


func game_over(collision_type: String) -> void:
	GameState.collision_type = collision_type
	stop_game()
	if collision_type == "wall":
		wall_collision.emit()
	elif collision_type == "self":
		self_collision.emit()
