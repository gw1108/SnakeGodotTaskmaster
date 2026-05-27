class_name ScoreStore
extends RefCounted

## Loads and persists the best score across sessions via a ConfigFile at
## user://snake.cfg. Static utility — no autoload registration needed.

const PATH := "user://snake.cfg"
const SECTION := "scores"
const KEY := "best"


## Return the persisted best score, or 0 if the file/key is missing (first run).
static func load_best() -> int:
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		return 0
	return int(config.get_value(SECTION, KEY, 0))


## Persist the given best score to user://snake.cfg.
static func save_best(score: int) -> void:
	var config := ConfigFile.new()
	# Preserve any other values already in the file.
	config.load(PATH)
	config.set_value(SECTION, KEY, score)
	config.save(PATH)
