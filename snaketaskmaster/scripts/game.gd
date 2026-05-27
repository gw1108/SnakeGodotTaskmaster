extends Node2D

## The Game shell. Owns the FSM, the tick clock (Timer), input capture, the
## RNG, the GameState data object, and the InputBuffer. All game *rules* are
## delegated to the pure logic modules; this node only translates engine events
## into calls on them and pushes results to the view / HUD / persistence.
##
## The view (BoardView), HUD, and screen overlays are added in later tasks, so
## every reference to them is resolved with get_node_or_null and guarded — the
## shell runs correctly with or without those children present.

enum GameMode { TITLE, PLAYING, PAUSED, GAME_OVER }

const GRID := Vector2i(25, 25)
const START_LENGTH := 3
const TICK_SECONDS := 0.125

var _state: GameState = null
var _input_buffer := InputBuffer.new()
var _rng := RandomNumberGenerator.new()
var _current_mode: GameMode = GameMode.TITLE
var _best_score := 0
var _new_best := false

@onready var _timer: Timer = $TickTimer
# Optional children, wired up by later tasks; all access is null-guarded.
@onready var _board_view: Node = get_node_or_null("BoardView")
@onready var _score_hud: Node = get_node_or_null("ScoreHUD")
@onready var _title_screen: Node = get_node_or_null("TitleScreen")
@onready var _pause_overlay: Node = get_node_or_null("PauseOverlay")
@onready var _game_over_screen: Node = get_node_or_null("GameOverScreen")


func _ready() -> void:
	_rng.randomize()
	_best_score = ScoreStore.load_best()
	_timer.wait_time = TICK_SECONDS
	_timer.one_shot = false
	if not _timer.timeout.is_connected(_on_tick):
		_timer.timeout.connect(_on_tick)
	_set_state(GameMode.TITLE)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm"):
		_on_confirm()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause"):
		_on_pause()
		get_viewport().set_input_as_handled()
		return
	if _current_mode == GameMode.PLAYING:
		var dir := _direction_from_event(event)
		if dir != Vector2i.ZERO:
			_input_buffer.push(dir)
			get_viewport().set_input_as_handled()


func _direction_from_event(event: InputEvent) -> Vector2i:
	if event.is_action_pressed("move_up"):
		return Vector2i.UP
	if event.is_action_pressed("move_down"):
		return Vector2i.DOWN
	if event.is_action_pressed("move_left"):
		return Vector2i.LEFT
	if event.is_action_pressed("move_right"):
		return Vector2i.RIGHT
	return Vector2i.ZERO


func _on_confirm() -> void:
	match _current_mode:
		GameMode.TITLE, GameMode.GAME_OVER:
			_start_new_game()
		GameMode.PAUSED:
			_set_state(GameMode.PLAYING)


func _on_pause() -> void:
	match _current_mode:
		GameMode.PLAYING:
			_set_state(GameMode.PAUSED)
		GameMode.PAUSED:
			_set_state(GameMode.PLAYING)


## Build (or reset in place) the run state and begin a new game.
func _start_new_game() -> void:
	if _state == null:
		_state = GameState.new_game(GRID, START_LENGTH)
	else:
		_state.reset(GRID, START_LENGTH)
	_input_buffer.clear()
	_new_best = false
	AppleLogic.spawn(_state, _rng)
	if _board_view != null:
		_board_view.set("_state", _state)
	_refresh_hud()
	_refresh_board()
	_set_state(GameMode.PLAYING)


## One authoritative simulation step, driven by Timer.timeout.
func _on_tick() -> void:
	if _current_mode != GameMode.PLAYING:
		return
	_state.direction = _input_buffer.consume(_state.direction)
	var result := SnakeLogic.advance(_state)
	match result:
		SnakeLogic.StepResult.MOVED:
			_refresh_board()
		SnakeLogic.StepResult.ATE:
			AppleLogic.spawn(_state, _rng)
			_refresh_hud()
			_safe_call(_board_view, "flash_eat")
			_refresh_board()
		SnakeLogic.StepResult.DIED:
			_timer.stop()
			if _state.score > _best_score:
				_best_score = _state.score
				ScoreStore.save_best(_best_score)
				_new_best = true
			_safe_call(_board_view, "flash_death")
			_set_state(GameMode.GAME_OVER)


## FSM transition: gate the tick timer and toggle screen visibility.
func _set_state(new_mode: GameMode) -> void:
	_current_mode = new_mode
	if new_mode == GameMode.PLAYING:
		_timer.start()
	else:
		_timer.stop()

	_set_node_visible(_title_screen, new_mode == GameMode.TITLE)
	_set_node_visible(_pause_overlay, new_mode == GameMode.PAUSED)
	_set_node_visible(_game_over_screen, new_mode == GameMode.GAME_OVER)
	_set_node_visible(_score_hud, new_mode != GameMode.TITLE)
	_set_node_visible(_board_view, new_mode != GameMode.TITLE)

	match new_mode:
		GameMode.TITLE:
			_safe_call(_title_screen, "set_best", [_best_score])
		GameMode.GAME_OVER:
			_safe_call(_game_over_screen, "set_scores", [_state.score, _best_score])
			_safe_call(_game_over_screen, "show_new_best", [_new_best])


func _refresh_hud() -> void:
	if _state != null:
		_safe_call(_score_hud, "set_scores", [_state.score, _best_score])


func _refresh_board() -> void:
	_safe_call(_board_view, "refresh")


func _set_node_visible(node: Node, is_visible: bool) -> void:
	if node != null:
		node.set("visible", is_visible)


func _safe_call(node: Node, method: String, args: Array = []) -> void:
	if node != null and node.has_method(method):
		node.callv(method, args)
