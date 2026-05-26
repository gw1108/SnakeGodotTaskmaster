extends Node2D
## Root game node. Owns the constant-rate tick that will drive all game logic,
## and paints the static arena (floor across the grid, deadly walls on the
## perimeter) into its TileMapLayers on startup.

## TileSet source ids, matching the atlas order in arena_tileset.tres.
const FLOOR_SOURCE_ID: int = 0
const WALL_SOURCE_ID: int = 1
## Every atlas here has a single tile at its top-left coordinate.
const ATLAS_ORIGIN: Vector2i = Vector2i(0, 0)

## Run lifecycle: ticks only advance the game while PLAYING.
enum GameState { PLAYING, GAME_OVER }
var game_state: GameState = GameState.PLAYING

## The player snake, driven by arrow-key input below and the tick above.
var snake: Snake
## The food the snake eats to grow; respawns to a new empty cell when eaten.
var food: Food
## Points earned this run; one per food eaten, shown in the HUD.
var score: int = 0


func _ready() -> void:
	_setup_floor()
	_setup_walls()
	snake = Snake.new()
	add_child(snake)
	food = Food.new()
	add_child(food)
	food.spawn(snake.body)
	_update_score_display()
	$TickTimer.start()


## Mirror the current score into the HUD label.
func _update_score_display() -> void:
	$HUD/ScoreLabel.text = "Score: %d" % score


## Map arrow keys to direction changes; set_direction() rejects reversals.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		snake.set_direction(Vector2i.UP)
	elif event.is_action_pressed("ui_down"):
		snake.set_direction(Vector2i.DOWN)
	elif event.is_action_pressed("ui_left"):
		snake.set_direction(Vector2i.LEFT)
	elif event.is_action_pressed("ui_right"):
		snake.set_direction(Vector2i.RIGHT)


func _setup_floor() -> void:
	for x in range(Grid.GRID_WIDTH):
		for y in range(Grid.GRID_HEIGHT):
			$Floor.set_cell(Vector2i(x, y), FLOOR_SOURCE_ID, ATLAS_ORIGIN)


func _setup_walls() -> void:
	for x in range(Grid.GRID_WIDTH):
		$Walls.set_cell(Vector2i(x, 0), WALL_SOURCE_ID, ATLAS_ORIGIN)
		$Walls.set_cell(Vector2i(x, Grid.GRID_HEIGHT - 1), WALL_SOURCE_ID, ATLAS_ORIGIN)
	for y in range(Grid.GRID_HEIGHT):
		$Walls.set_cell(Vector2i(0, y), WALL_SOURCE_ID, ATLAS_ORIGIN)
		$Walls.set_cell(Vector2i(Grid.GRID_WIDTH - 1, y), WALL_SOURCE_ID, ATLAS_ORIGIN)


func _on_tick() -> void:
	if game_state != GameState.PLAYING:
		return

	snake.move()

	# A wall hit leaves the grid; running into itself ends the run too.
	if not Grid.is_in_bounds(snake.get_head()) or snake.check_self_collision():
		_game_over()
		return

	if snake.get_head() == food.grid_pos:
		food.play_eat_sound()
		snake.grow()
		score += 1
		_update_score_display()
		food.spawn(snake.body)


## End the run: freeze the tick, play the death sound, and surface the
## game-over overlay. State stays GAME_OVER until _restart_game() resets it.
func _game_over() -> void:
	game_state = GameState.GAME_OVER
	$TickTimer.stop()
	$DeathSound.play()
	$HUD/GameOverPanel.visible = true


## While the run is over, the R key starts a fresh game; ignored mid-run.
func _input(event: InputEvent) -> void:
	if game_state != GameState.GAME_OVER:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_restart_game()


## Wipe the run back to its starting state: reset score, rebuild the snake at
## its starting position/length, respawn food, hide the overlay, and resume ticks.
func _restart_game() -> void:
	score = 0
	_update_score_display()
	snake.queue_free()
	snake = Snake.new()
	add_child(snake)
	food.spawn(snake.body)
	game_state = GameState.PLAYING
	$HUD/GameOverPanel.visible = false
	$TickTimer.start()
