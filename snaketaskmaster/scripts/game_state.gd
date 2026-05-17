extends Node

# Cross-scene game state. Tracks collision cause for the game-over screen
# plus score/high-score so they survive scene reloads between runs.
var collision_type: String = ""
var current_score: int = 0
var high_score: int = 0


func reset() -> void:
	collision_type = ""
	current_score = 0


func add_score(amount: int) -> void:
	current_score += amount
	update_high_score()


func reset_score() -> void:
	current_score = 0


func update_high_score() -> void:
	if current_score > high_score:
		high_score = current_score
