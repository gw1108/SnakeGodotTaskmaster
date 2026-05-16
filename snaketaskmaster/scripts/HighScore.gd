extends Node

const SAVE_PATH := "user://highscore.save"

var high_score: int = 0

func _ready() -> void:
	load_high_score()

func load_high_score() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		high_score = 0
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		high_score = 0
		return
	var data := file.get_as_text()
	file.close()
	high_score = int(data)

func save_high_score(new_score: int) -> void:
	if new_score <= high_score:
		return
	high_score = new_score
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(str(high_score))
	file.close()

func get_high_score() -> int:
	return high_score
