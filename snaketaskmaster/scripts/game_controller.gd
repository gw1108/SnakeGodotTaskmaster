extends Node2D
class_name GameController
## Root controller for Main.tscn: owns the snake, drives the fixed-interval
## tick, and runs the PLAYING/GAME_OVER state machine.
##
## Each tick advances the snake exactly one grid cell. Input handling, food,
## collision, rendering, and audio are layered on in later tasks; this script
## provides the loop and state they hook into.

enum GameState { PLAYING, GAME_OVER }

## Seconds between ticks (one snake step per tick).
const TICK_INTERVAL := 0.15

## Sprites for the snake and food (placeholder art generated at 32x32).
const HEAD_SPRITE: Texture2D = preload("res://source/sprites/player_head.png")
const BODY_SPRITE: Texture2D = preload("res://source/sprites/player_body.png")
const FOOD_SPRITE: Texture2D = preload("res://source/sprites/food.png")

## Head rotation per movement direction. The head texture faces RIGHT, so
## RIGHT is 0 degrees and the others rotate from there.
const HEAD_ROTATIONS := {
	Vector2i.UP: -90.0,
	Vector2i.DOWN: 90.0,
	Vector2i.LEFT: 180.0,
	Vector2i.RIGHT: 0.0,
}

var state: GameState = GameState.PLAYING
var snake: Snake
var score: int = 0
var high_score: int = 0
var tick_timer: Timer
## Grid cell currently holding food. Set by spawn_food().
var food_position: Vector2i

## Container holding one Sprite2D per snake segment, rebuilt each tick.
var snake_visuals: Node2D
## Single sprite repositioned onto the current food cell.
var food_sprite: Sprite2D

## UI labels live in Main.tscn. get_node_or_null keeps update_ui() safe when the
## controller is built bare via .new() (e.g. unit tests) and the labels are absent.
@onready var score_label: Label = get_node_or_null("ScoreLabel")
@onready var game_over_label: Label = get_node_or_null("GameOverLabel")

func _ready() -> void:
	tick_timer = Timer.new()
	tick_timer.wait_time = TICK_INTERVAL
	tick_timer.one_shot = false
	tick_timer.timeout.connect(_on_tick)
	add_child(tick_timer)
	# Added after any scene children (e.g. the arena background) so the snake and
	# food draw on top of it; Node2D z-orders siblings by tree order.
	snake_visuals = Node2D.new()
	add_child(snake_visuals)
	food_sprite = Sprite2D.new()
	food_sprite.texture = FOOD_SPRITE
	add_child(food_sprite)
	reset_game()

## Polls input every frame. While PLAYING, the held movement key steers the
## snake (set_direction rejects 180-degree reversals). In GAME_OVER, any key
## press restarts the game.
func _process(_delta: float) -> void:
	if state == GameState.GAME_OVER:
		# Any key restarts. is_anything_pressed() covers real physical input;
		# the movement-action check makes restart reachable in headless tests
		# (Input.action_press doesn't flag is_anything_pressed()).
		if Input.is_anything_pressed() or _poll_direction() != Vector2i.ZERO:
			reset_game()
		return
	var dir := _poll_direction()
	if dir != Vector2i.ZERO:
		snake.set_direction(dir)

## Returns the grid step for the currently held movement action, or
## Vector2i.ZERO when none is held. Up is checked first, then down/left/right,
## so simultaneous presses resolve deterministically.
func _poll_direction() -> Vector2i:
	if Input.is_action_pressed("move_up"):
		return Vector2i.UP
	if Input.is_action_pressed("move_down"):
		return Vector2i.DOWN
	if Input.is_action_pressed("move_left"):
		return Vector2i.LEFT
	if Input.is_action_pressed("move_right"):
		return Vector2i.RIGHT
	return Vector2i.ZERO

## Executes one game step. Ignored unless PLAYING so a stopped/over game can't
## advance. If the cell ahead holds food the snake grows (and respawns food)
## instead of plain-moving, so eating never double-advances the head. After the
## move, a head on a border cell or overlapping the body ends the game. Food
## only spawns on interior cells, so eating can never coincide with a wall hit.
func _on_tick() -> void:
	if state != GameState.PLAYING:
		return
	if snake.get_head() + snake.direction == food_position:
		snake.grow()
		score += 1
		# (eat sound is added by the later audio task)
		spawn_food()
	else:
		snake.move_forward()
	if Grid.is_border_cell(snake.get_head()) or snake.is_colliding_with_self():
		game_over()
	update_ui()
	update_visuals()

## Places food on a random interior cell (never a border, never on the snake).
## No-op if the snake fills every interior cell, keeping the old food in place.
func spawn_food() -> void:
	var empty_cells: Array[Vector2i] = []
	for x in range(1, Grid.GRID_WIDTH - 1):
		for y in range(1, Grid.GRID_HEIGHT - 1):
			var cell := Vector2i(x, y)
			if not snake.body.has(cell):
				empty_cells.append(cell)
	if empty_cells.is_empty():
		return
	food_position = empty_cells.pick_random()

## Starts a fresh game: new snake, zeroed score, PLAYING, timer running.
func reset_game() -> void:
	snake = Snake.new()
	score = 0
	state = GameState.PLAYING
	spawn_food()
	if tick_timer != null:
		tick_timer.start()
	update_ui()
	update_visuals()

## Ends the game: stops the tick, records a new high score, enters GAME_OVER.
func game_over() -> void:
	if tick_timer != null:
		tick_timer.stop()
	high_score = maxi(high_score, score)
	state = GameState.GAME_OVER
	update_ui()

## Syncs the score and game-over labels to the current state. The score label
## shows only while PLAYING; the game-over panel shows only in GAME_OVER. Safe to
## call when the labels are absent (a controller built via .new() in unit tests).
func update_ui() -> void:
	if score_label != null:
		score_label.text = "Score: %d" % score
		score_label.visible = (state == GameState.PLAYING)
	if game_over_label != null:
		game_over_label.visible = (state == GameState.GAME_OVER)
		if state == GameState.GAME_OVER:
			game_over_label.text = "GAME OVER\nScore: %d\nHigh Score: %d\nPress any key to restart" % [score, high_score]

## Redraws the snake and food. Snake sprites are rebuilt from scratch each call
## (cleared then recreated) so length and direction changes are always reflected;
## the food sprite is just repositioned. Sprites are centered on their cell, so
## head rotation pivots about the cell center. Safe to call before _ready creates
## the visual nodes (a controller built via .new() before being added to the tree).
func update_visuals() -> void:
	if snake_visuals == null or food_sprite == null:
		return
	var center := Vector2(Grid.CELL_SIZE / 2.0, Grid.CELL_SIZE / 2.0)
	for child in snake_visuals.get_children():
		child.queue_free()
	for i in snake.body.size():
		var sprite := Sprite2D.new()
		sprite.texture = HEAD_SPRITE if i == 0 else BODY_SPRITE
		sprite.position = Grid.cell_to_pixel(snake.body[i]) + center
		if i == 0:
			sprite.rotation_degrees = HEAD_ROTATIONS[snake.direction]
		snake_visuals.add_child(sprite)
	food_sprite.position = Grid.cell_to_pixel(food_position) + center
