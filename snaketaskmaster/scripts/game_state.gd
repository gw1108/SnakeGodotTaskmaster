extends Node

# Cross-scene game state. Currently tracks how the player died so the
# game-over screen can display the collision type.
var collision_type: String = ""


func reset() -> void:
	collision_type = ""
