extends Node

@export var snake_scene: PackedScene

var score: int
var game_started: bool = false

# grid variables
var cells: int = 16
var cell_size: int = 25

# food vars
var food_pos : Vector2
var regen_food : bool = true

# Snake Variables
var old_data: Array
var snake_data: Array
var snake: Array

var start_pos = Vector2(3, 3)
var up = Vector2(0, -1)
var down = Vector2(0, 1)
var left = Vector2(-1, 0)
var right = Vector2(1, 0)
var move_direction : Vector2
var can_move : bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	new_game()
	
func new_game() -> void:
	get_tree().call_group("segments", "queue_free")
	get_tree().paused = false
	$GameOver.hide()
	score = 0
	$hud.get_node("ScorePanel/ScoreLabel").text = "Score: " + str(score)
	move_direction = up
	can_move = true
	generate_snake()
	move_food()
	
func generate_snake() -> void:
	old_data.clear()
	snake_data.clear()
	snake.clear()
	# generate snake vertically down
	for i in range(3):
		add_segment(start_pos + Vector2(0, i))

func add_segment(pos) -> void:
	snake_data.append(pos)
	var SnakeSegment = snake_scene.instantiate()
	SnakeSegment.position = (pos * cell_size) + Vector2(0, cell_size)
	add_child(SnakeSegment)
	snake.append(SnakeSegment)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	move_snake()

func check_food_eaten() -> void:
	if snake_data[0] == food_pos:
		score += 1
		$hud.get_node("ScorePanel/ScoreLabel").text = "Score: " + str(score)
		add_segment(old_data[-1])
		move_food()

func move_snake() -> void:
	if can_move:
		if Input.is_action_just_pressed("move_down") and move_direction != up:
			move_direction = down
			can_move = false;
			if not game_started:
				start_game()
		if Input.is_action_just_pressed("move_up") and move_direction != down:
			move_direction = up
			can_move = false;
			if not game_started:
				start_game()
		if Input.is_action_just_pressed("move_left") and move_direction != right:
			move_direction = left
			can_move = false;
			if not game_started:
				start_game()
		if Input.is_action_just_pressed("move_right") and move_direction != left:
			move_direction = right
			can_move = false;
			if not game_started:
				start_game()
				
func start_game() -> void:
	game_started = true
	$Timer.start()

func _on_timer_timeout() -> void:
	can_move = true
	old_data = [] + snake_data
	snake_data[0] += move_direction
	for i in range(len(snake_data)):
		if i > 0:
			snake_data[i] = old_data[i-1]
		snake[i].position = (snake_data[i] * cell_size) + Vector2(0, cell_size)
	check_out_of_bounds()
	check_self_eaten()
	check_food_eaten()
	
func check_out_of_bounds() -> void:
	if snake_data[0].x < 0 or snake_data[0].x > cells - 1 or snake_data[0].y < 0 or snake_data[0].y > cells - 1:
		end_game()
		
func check_self_eaten() -> void:
	for i in range(1, len(snake_data)):
		if snake_data[0] == snake_data[i]:
			end_game()

func move_food() -> void:
	while regen_food:
		regen_food = false
		food_pos = Vector2(randi_range(0, cells - 1), randi_range(0, cells - 1))
		for i in snake_data:
			if food_pos == i:
				regen_food = true
				break;
	$Food.position = (food_pos * cell_size) + Vector2(0, cell_size)
	regen_food=true

func end_game() -> void:
	$GameOver.show()
	$Timer.stop()
	game_started = false
	get_tree().paused = true

func _on_game_over_restart() -> void:
	new_game()
