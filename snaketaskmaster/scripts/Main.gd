extends Node

var current_scene: Node = null

func _ready() -> void:
	load_menu()

func load_menu() -> void:
	change_scene("res://scenes/MainMenu.tscn")

func load_game() -> void:
	change_scene("res://scenes/Game.tscn")

func change_scene(path: String) -> void:
	if current_scene:
		current_scene.queue_free()
	if not ResourceLoader.exists(path):
		push_warning("Scene not found: %s" % path)
		return
	var scene := load(path).instantiate()
	add_child(scene)
	current_scene = scene
