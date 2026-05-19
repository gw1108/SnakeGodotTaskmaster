extends Node

signal tick_occurred

const TICK_RATE := 0.15

@onready var timer: Timer = $Timer


func _ready() -> void:
	timer.wait_time = TICK_RATE
	timer.one_shot = false
	timer.autostart = false
	if not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)


func start_tick() -> void:
	timer.start()


func stop_tick() -> void:
	timer.stop()


func is_running() -> bool:
	return not timer.is_stopped()


func _on_timer_timeout() -> void:
	tick_occurred.emit()
