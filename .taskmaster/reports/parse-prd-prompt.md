# parse-prd Prompt Trace

## Metadata
- **timestamp:** 2026-05-24T02:18:22.574Z
- **research:** false
- **append:** false
- **nextId:** 1
- **variant:** default

## System Prompt

```
You are tasked with analyzing Product Requirements Documents (PRDs) and generating a structured, logically ordered, dependency-aware and sequenced list of development tasks in JSON format.

Analyze the provided PRD content and generate approximately 10 top-level development tasks. If the complexity or the level of detail of the PRD is high, generate more tasks relative to the complexity of the PRD
Each task should represent a logical unit of work needed to implement the requirements and focus on the most direct and effective way to implement the requirements without unnecessary complexity or overengineering. Include pseudo-code and implementation details for each task. Find the most up to date information to implement each task.
Assign sequential IDs starting from 1. Infer title, description, and details for each task based *only* on the PRD content.
Set status to 'pending', dependencies to an empty array [], and priority to 'medium' initially for all tasks.
Generate a response containing a single key "tasks", where the value is an array of task objects adhering to the provided schema.

Each task should follow this JSON structure:
{
	"id": number,
	"title": string,
	"description": string,
	"status": "pending",
	"dependencies": number[] (IDs of tasks this depends on),
	"priority": "high" | "medium" | "low",
	"details": string (implementation details)
}

Guidelines:
1. Unless complexity warrants otherwise, create exactly 10 tasks, numbered sequentially starting from 1
2. Each task should be atomic and focused on a single responsibility following the most up to date best practices and standards
3. Order tasks logically - consider dependencies and implementation sequence
4. Early tasks should focus on setup, core functionality first, then advanced features
5. To verify, update the golden path test or add unit tests. You do not have to test if there is not sufficient complexity or edge cases. Test strategy, if any, should never have manual testing.
6. Set appropriate dependency IDs (a task can only depend on tasks with lower IDs, potentially including existing tasks with IDs less than 1 if applicable)
7. Assign priority (high/medium/low) based on criticality and dependency order
8. Include detailed implementation guidance in the "details" field
9. If the PRD contains specific requirements for libraries, database schemas, frameworks, tech stacks, or any other implementation details, STRICTLY ADHERE to these requirements in your task breakdown and do not discard them under any circumstance
10. Focus on filling in any gaps left by the PRD or areas that aren't fully specified, while preserving all explicit requirements
11. Always aim to provide the most direct path to implementation, avoiding over-engineering or roundabout approaches
```

## User Prompt

```
## IMPORTANT: Codebase Analysis Required

You have access to powerful codebase analysis tools. Before generating tasks:

1. Use the Glob tool to explore the project structure (e.g., "**/*.js", "**/*.json", "**/README.md")
2. Use the Grep tool to search for existing implementations, patterns, and technologies
3. Use the Read tool to examine key files like package.json, README.md, and main entry points
4. Analyze the current state of implementation to understand what already exists

Based on your analysis:
- Identify what components/features are already implemented
- Understand the technology stack, frameworks, and patterns in use
- Generate tasks that build upon the existing codebase rather than duplicating work
- Ensure tasks align with the project's current architecture and conventions

Project Root: C:\GameDev\SnakeGodotTaskmaster

Here's the Product Requirements Document (PRD) to break down into approximately 10 tasks, starting IDs from 1:

<context>
# Overview
A simple, classic 2D Snake game built in Godot. The player steers a continuously
moving snake around a bordered, top-down arena, eating apples to grow longer. The
challenge comes from avoiding the deadly outer walls and the snake's own ever-growing
body. It is for casual players who want a quick, familiar arcade experience, and it
serves as a small, well-scoped reference project.

The game is intentionally minimal: one screen, one snake, one food item at a time,
and a score that goes up as you eat. There is no win state — the player tries to beat
their own high score before they crash.

# Core Features
- Grid-based arena with a deadly wall border and a grass floor.
- A snake (head + trailing body segments) that moves at a constant speed on a fixed grid tick.
- Absolute 4-direction steering (Arrow keys / WASD map to up/down/left/right). The snake
  cannot immediately reverse into itself.
- Food (apple) that spawns on a random empty cell; eating it grows the snake by one segment
  and increases the score.
- Collision rules: the run ends if the head hits the wall border or any body segment.
- A score display during play and a high score tracked for the current session.
- Game over flow: a death sound plays, the final score and high score are shown with a
  "press to restart" prompt, and pressing a key starts a new run.
- Sound effects for eating food and for dying.

# User Experience
- Single player, single screen, top-down perspective.
- Player flow: launch → snake is already moving → steer to eat apples and grow → crash into
  wall or self → see score + restart prompt → press a key → new run begins.
- UI/UX: a clean grass playfield framed by a brick wall border, a readable score in a corner,
  and a clear game-over message. Controls are immediate and require no menus to start playing.
</context>

<PRD>
# Technical Architecture
- Engine: Godot 4 (GDScript). The project lives in `snaketaskmaster/`.
- 2D, top-down, grid-based. The arena is a fixed grid of cells; all positions (snake segments,
  food, walls) are cell coordinates. Movement advances one cell per game tick at a constant rate.
- Core components:
  - Arena/Grid: defines grid dimensions and cell size, draws the floor and wall border, and
    converts between grid cells and pixel positions.
  - Snake: an ordered list of grid cells (head first). On each tick it moves forward; on eating
    it appends a segment instead of dropping the tail.
  - Food: a single apple occupying one empty cell; respawns to a new random empty cell when eaten.
  - Game controller: owns the tick timer, input, scoring, collision checks, and the
    play/game-over state machine.
- Data: snake body as an Array of Vector2i cells; current direction as a Vector2i; score and
  session high score as ints.

# Asset Inventory
All required assets already exist in the repo and should be used as-is.
- Sprites (`source/sprites/`): `player_head.png`, `player_body.png`, `food.png`,
  `floor_tile.png`, `wall_tile.png`.
- Audio (`source/audio/`): `eat_food.wav`, `death.wav`.

# Features / Tasks
Each task is tagged with exactly one of [code], [art], or [audio]. Art tasks name the sprite
to use; audio tasks name the sound file to use. Tasks that would need more than one discipline
are split so each task needs only one.

## Foundation
- [code] Project & scene setup: create the main game scene and root game controller script in
  `snaketaskmaster/`, wire up the game loop entry point.
- [code] Grid system: define grid dimensions and cell size; provide cell <-> pixel conversion
  helpers used by every visual and movement task.
- [code] Game tick: a fixed-interval timer that advances the game one step at a constant speed.

## Snake & movement
- [code] Snake data model: maintain the ordered list of body cells with the head first.
- [code] Movement: on each tick, move the snake forward one cell in the current direction.
- [code] Input handling: read Arrow keys / WASD as absolute up/down/left/right; update the
  direction; reject the immediate 180-degree reversal.

## Food & growth
- [code] Food spawning: place the apple on a random empty cell, and respawn it when eaten.
- [code] Eating & growth: when the head enters the food cell, grow the snake by one segment and
  increment the score.

## Collisions & game state
- [code] Collision detection: end the run when the head enters a wall-border cell or any body cell.
- [code] Score & high score: track the current score and the highest score of the session.
- [code] Game over & restart: enter a game-over state on death, show the final score, high score,
  and a "press to restart" prompt; on input, reset and start a new run.

## Visuals (art)
- [art] Floor background: tile the playfield using `source/sprites/floor_tile.png`.
- [art] Wall border: draw the deadly arena border using `source/sprites/wall_tile.png`.
- [art] Snake head sprite: render the head segment using `source/sprites/player_head.png`
  (oriented to face the current movement direction).
- [art] Snake body sprite: render each trailing body segment using `source/sprites/player_body.png`.
- [art] Food sprite: render the apple using `source/sprites/food.png`.

## UI (code)
- [code] Score & game-over UI: on-screen Label(s) showing the live score during play and the
  final score, high score, and restart prompt on game over.

## Audio
- [audio] Eat sound: play `source/audio/eat_food.wav` when the snake eats food.
- [audio] Death sound: play `source/audio/death.wav` when the snake dies.

# Development Roadmap
- MVP (everything above): a fully playable single-screen Snake game with art, scoring, restart,
  and sound. This is the complete intended scope.
- Order of build: foundation (scene, grid, tick) first so movement is visible as early as
  possible, then snake movement and input, then food and growth, then collisions and game state,
  then visuals and audio polish.

# Logical Dependency Chain
1. Project & scene setup, grid system, and game tick — nothing else works without these.
2. Snake data model and movement (need the grid + tick); then input handling (needs movement).
3. Food spawning and eating/growth (need the snake and grid).
4. Collision detection, score/high score, and game over/restart (need movement, food, and growth).
5. Visuals: floor and wall border can be done after the grid; snake head/body and food sprites
   after the snake and food exist.
6. UI score/game-over display after scoring and game-over state exist.
7. Audio: eat sound after eating exists; death sound after game-over exists.

# Risks and Mitigations
- Reverse-into-self bug: a snake longer than one segment must not be allowed to instantly turn
  180 degrees. Mitigation: reject the opposite-of-current direction in input handling and test it.
- Food spawning on the snake or in a wall: mitigation: only choose from empty, non-wall cells.
- Off-by-one at the border: the wall cells must align with the grid so collisions read correctly.
  Mitigation: derive wall cells from the grid system, not from hard-coded pixels.

# Appendix
- Source concept: `.firecrawl/snake-gameplay-extracted.md` (classic top-down Snake — growing line,
  eat food to grow, avoid walls and self-collision).
- Confirmed design decisions: absolute 4-direction controls; deadly wall border (no wrap-around);
  constant snake speed; on death show score + high score + restart prompt.
</PRD>


IMPORTANT: Your response must be a JSON object with a "tasks" property containing an array of task objects. You may optionally include a "metadata" object. Do not include any other properties.
```

## LLM Response

```json
{
  "tasks": [
    {
      "id": 1,
      "title": "Grid System & Arena Setup",
      "description": "[code] Define the grid-based coordinate system, cell size, arena dimensions, and provide grid ↔ pixel conversion utilities",
      "details": "Create `scripts/grid.gd` as a static class or autoload:\n- Define constants: CELL_SIZE (e.g., 32px), GRID_WIDTH (20), GRID_HEIGHT (15)\n- Implement `cell_to_pixel(cell: Vector2i) -> Vector2` returning top-left corner of the cell\n- Implement `pixel_to_cell(pos: Vector2) -> Vector2i` for reverse conversion\n- Implement `is_valid_cell(cell: Vector2i) -> bool` checking 0 <= x < GRID_WIDTH and 0 <= y < GRID_HEIGHT\n- Implement `is_border_cell(cell: Vector2i) -> bool` returning true if cell is on the outer edge (x==0 or x==GRID_WIDTH-1 or y==0 or y==GRID_HEIGHT-1)\n\nPseudo-code:\n```gdscript\nclass_name Grid\nconst CELL_SIZE = 32\nconst GRID_WIDTH = 20\nconst GRID_HEIGHT = 15\n\nstatic func cell_to_pixel(cell: Vector2i) -> Vector2:\n    return Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE)\n\nstatic func is_border_cell(cell: Vector2i) -> bool:\n    return cell.x == 0 or cell.x == GRID_WIDTH - 1 or cell.y == 0 or cell.y == GRID_HEIGHT - 1\n```",
      "testStrategy": "Unit test grid conversions, boundary checks, and border detection",
      "priority": "high",
      "dependencies": [],
      "status": "pending"
    },
    {
      "id": 2,
      "title": "Snake Data Model",
      "description": "[code] Implement the snake as an ordered list of grid cells (head-first) with direction tracking",
      "details": "Create `scripts/snake.gd`:\n- `var body: Array[Vector2i]` storing segments with head at index 0\n- `var direction: Vector2i` current movement direction (one of Vector2i.UP/DOWN/LEFT/RIGHT)\n- `func _init()` initializes snake at center (Grid.GRID_WIDTH/2, Grid.GRID_HEIGHT/2) with 3 segments facing right\n- `func get_head() -> Vector2i` returns body[0]\n- `func move_forward()` adds new head at (head + direction), removes tail\n- `func grow()` adds new head without removing tail\n- `func set_direction(new_dir: Vector2i)` with 180-degree reversal prevention: if body.size() > 1 and new_dir == -direction, reject\n- `func is_colliding_with_self() -> bool` checks if head position exists in body[1..end]\n\nPseudo-code:\n```gdscript\nclass_name Snake\nvar body: Array[Vector2i] = []\nvar direction := Vector2i.RIGHT\n\nfunc _init():\n    var start := Vector2i(Grid.GRID_WIDTH / 2, Grid.GRID_HEIGHT / 2)\n    body = [start, start - Vector2i.RIGHT, start - Vector2i.RIGHT * 2]\n\nfunc move_forward():\n    body.insert(0, body[0] + direction)\n    body.pop_back()\n\nfunc set_direction(new_dir: Vector2i):\n    if body.size() > 1 and new_dir == -direction:\n        return  # reject 180 reversal\n    direction = new_dir\n```",
      "testStrategy": "Unit test initialization, movement, growth, self-collision detection, and 180-degree reversal prevention",
      "priority": "high",
      "dependencies": [
        1
      ],
      "status": "pending"
    },
    {
      "id": 3,
      "title": "Game Controller & Tick System",
      "description": "[code] Create the main game controller with fixed-interval tick timer and game state management",
      "details": "Create `scripts/game_controller.gd` as the root script for Main.tscn:\n- Enum `GameState { PLAYING, GAME_OVER }`\n- `var state: GameState = GameState.PLAYING`\n- `var snake: Snake`\n- `var score: int = 0`\n- `var high_score: int = 0`\n- `var tick_timer: Timer`\n- `func _ready()` initializes snake, creates Timer node with wait_time=0.15, one_shot=false, connects timeout to `_on_tick()`\n- `func _on_tick()` executes one game step: move snake, check collisions, update food\n- `func reset_game()` reinitializes snake, score, clears food, sets state to PLAYING, starts timer\n- `func game_over()` stops timer, plays death sound, updates high_score if needed, sets state to GAME_OVER\n\nPseudo-code:\n```gdscript\nextends Node2D\nenum GameState { PLAYING, GAME_OVER }\nvar state := GameState.PLAYING\nvar snake: Snake\nvar tick_timer: Timer\n\nfunc _ready():\n    snake = Snake.new()\n    tick_timer = Timer.new()\n    tick_timer.wait_time = 0.15\n    tick_timer.one_shot = false\n    tick_timer.timeout.connect(_on_tick)\n    add_child(tick_timer)\n    tick_timer.start()\n\nfunc _on_tick():\n    if state != GameState.PLAYING: return\n    snake.move_forward()\n    # collision & food checks follow\n```",
      "testStrategy": "Unit test game state transitions, tick execution, score tracking, and reset functionality",
      "priority": "high",
      "dependencies": [
        2
      ],
      "status": "pending"
    },
    {
      "id": 4,
      "title": "Input Handling",
      "description": "[code] Map Arrow keys and WASD to absolute 4-direction control with 180-degree reversal prevention",
      "details": "In `scripts/game_controller.gd`, add `_input(event)` or `_process(delta)` with Input polling:\n- Map Input.is_action_pressed(\"ui_up\") or KEY_W → Vector2i.UP\n- Map Input.is_action_pressed(\"ui_down\") or KEY_S → Vector2i.DOWN\n- Map Input.is_action_pressed(\"ui_left\") or KEY_A → Vector2i.LEFT\n- Map Input.is_action_pressed(\"ui_right\") or KEY_D → Vector2i.RIGHT\n- Call `snake.set_direction(new_dir)` which already handles reversal rejection\n- In GAME_OVER state, any key press calls `reset_game()`\n\nDefine input actions in project.godot if not using default ui_* actions:\n```ini\n[input]\nmove_up={\"key\": \"W\", \"key\": \"Up\"}\nmove_down={\"key\": \"S\", \"key\": \"Down\"}\nmove_left={\"key\": \"A\", \"key\": \"Left\"}\nmove_right={\"key\": \"D\", \"key\": \"Right\"}\n```\n\nPseudo-code:\n```gdscript\nfunc _process(_delta):\n    if state == GameState.GAME_OVER:\n        if Input.is_anything_pressed(): reset_game()\n        return\n    if Input.is_action_pressed(\"ui_up\"): snake.set_direction(Vector2i.UP)\n    elif Input.is_action_pressed(\"ui_down\"): snake.set_direction(Vector2i.DOWN)\n    elif Input.is_action_pressed(\"ui_left\"): snake.set_direction(Vector2i.LEFT)\n    elif Input.is_action_pressed(\"ui_right\"): snake.set_direction(Vector2i.RIGHT)\n```",
      "testStrategy": "Unit test direction changes, reversal rejection with snake length > 1, and game-over restart input",
      "priority": "high",
      "dependencies": [
        3
      ],
      "status": "pending"
    },
    {
      "id": 5,
      "title": "Food Spawning System",
      "description": "[code] Spawn food at random empty (non-wall, non-snake) grid cells and handle respawning on consumption",
      "details": "In `scripts/game_controller.gd`:\n- `var food_position: Vector2i` stores current food cell\n- `func spawn_food()` finds random empty cell:\n  - Collect all valid cells (0 < x < GRID_WIDTH-1, 0 < y < GRID_HEIGHT-1) excluding snake body\n  - Randomly select one: `food_position = empty_cells.pick_random()`\n- `func check_food_collision()` in `_on_tick()`:\n  - If snake.get_head() == food_position: snake.grow(), score += 1, play eat sound, spawn_food()\n\nPseudo-code:\n```gdscript\nvar food_position: Vector2i\n\nfunc spawn_food():\n    var empty_cells: Array[Vector2i] = []\n    for x in range(1, Grid.GRID_WIDTH - 1):\n        for y in range(1, Grid.GRID_HEIGHT - 1):\n            var cell := Vector2i(x, y)\n            if not snake.body.has(cell):\n                empty_cells.append(cell)\n    food_position = empty_cells.pick_random()\n\nfunc _on_tick():\n    snake.move_forward()\n    if snake.get_head() == food_position:\n        snake.grow()\n        score += 1\n        spawn_food()\n```",
      "testStrategy": "Unit test food spawning excludes walls and snake body, collision detection triggers growth and scoring",
      "priority": "medium",
      "dependencies": [
        3
      ],
      "status": "pending"
    },
    {
      "id": 6,
      "title": "Collision Detection",
      "description": "[code] Detect wall and self-collision; trigger game over on collision",
      "details": "In `scripts/game_controller.gd`, in `_on_tick()` after moving:\n- Check wall collision: `if Grid.is_border_cell(snake.get_head()): game_over()`\n- Check self-collision: `if snake.is_colliding_with_self(): game_over()`\n\nOrder in `_on_tick()`:\n1. snake.move_forward()\n2. Check wall collision\n3. Check self-collision\n4. Check food collision (grow if eating)\n\nPseudo-code:\n```gdscript\nfunc _on_tick():\n    if state != GameState.PLAYING: return\n    snake.move_forward()\n    var head := snake.get_head()\n    if Grid.is_border_cell(head) or snake.is_colliding_with_self():\n        game_over()\n        return\n    if head == food_position:\n        snake.grow()\n        score += 1\n        spawn_food()\n```",
      "testStrategy": "Unit test wall collision triggers game over, self-collision triggers game over, eating does not trigger collision",
      "priority": "high",
      "dependencies": [
        3,
        5
      ],
      "status": "pending"
    },
    {
      "id": 7,
      "title": "Visual Rendering - Floor & Walls",
      "description": "[art] Render grid floor tiles and deadly wall border using TileMap or sprite positioning",
      "details": "In Main.tscn, add a TileMap node or use individual Sprite2D nodes:\n\nOption A (TileMap - recommended):\n- Create TileMap node as child of Main\n- Create TileSet resource with two tiles:\n  - Tile 0: `source/sprites/floor_tile.png` for interior\n  - Tile 1: `source/sprites/wall_tile.png` for border\n- In `_ready()` of game_controller.gd, populate TileMap:\n  - For each cell in grid, set border cells to tile 1, interior to tile 0\n\nOption B (Sprite2D array):\n- For each grid cell, instantiate Sprite2D at Grid.cell_to_pixel(cell)\n- Use `floor_tile.png` for interior, `wall_tile.png` for border\n- Parent all to a \"Background\" Node2D\n\nPseudo-code (TileMap):\n```gdscript\nvar tile_map: TileMap\n\nfunc _ready():\n    tile_map = $TileMap  # reference TileMap child\n    for x in Grid.GRID_WIDTH:\n        for y in Grid.GRID_HEIGHT:\n            var cell := Vector2i(x, y)\n            var tile_id := 1 if Grid.is_border_cell(cell) else 0\n            tile_map.set_cell(0, cell, 0, Vector2i(tile_id, 0))\n```\n\nNote: Assets must exist at `source/sprites/floor_tile.png` and `source/sprites/wall_tile.png`. Create placeholder assets if needed.",
      "priority": "medium",
      "dependencies": [
        1,
        3
      ],
      "status": "pending"
    },
    {
      "id": 8,
      "title": "Visual Rendering - Snake & Food",
      "description": "[art] Render snake head, body segments, and food sprite with proper positioning and rotation",
      "details": "In `scripts/game_controller.gd`, add visual node management:\n- Preload sprites: `const HEAD_SPRITE = preload(\"res://source/sprites/player_head.png\")`, `const BODY_SPRITE = preload(\"res://source/sprites/player_body.png\")`, `const FOOD_SPRITE = preload(\"res://source/sprites/food.png\")`\n- Create container nodes in `_ready()`: `var snake_visuals: Node2D`, `var food_sprite: Sprite2D`\n- `func update_visuals()`:\n  - Clear and recreate snake sprites:\n    - For each segment in snake.body, create Sprite2D at Grid.cell_to_pixel(segment) + offset to center\n    - Head (index 0) uses HEAD_SPRITE with rotation based on direction: UP=-90°, DOWN=90°, LEFT=180°, RIGHT=0°\n    - Body segments use BODY_SPRITE (no rotation needed)\n  - Update food sprite position to Grid.cell_to_pixel(food_position) + center offset\n- Call `update_visuals()` in `_on_tick()` after all game logic\n\nPseudo-code:\n```gdscript\nfunc update_visuals():\n    # Clear old snake sprites\n    for child in snake_visuals.get_children(): child.queue_free()\n    \n    # Render snake\n    for i in snake.body.size():\n        var sprite := Sprite2D.new()\n        sprite.texture = HEAD_SPRITE if i == 0 else BODY_SPRITE\n        sprite.position = Grid.cell_to_pixel(snake.body[i]) + Vector2(Grid.CELL_SIZE/2, Grid.CELL_SIZE/2)\n        if i == 0:  # rotate head\n            sprite.rotation_degrees = {Vector2i.UP: -90, Vector2i.DOWN: 90, Vector2i.LEFT: 180, Vector2i.RIGHT: 0}[snake.direction]\n        snake_visuals.add_child(sprite)\n    \n    # Update food\n    food_sprite.position = Grid.cell_to_pixel(food_position) + Vector2(Grid.CELL_SIZE/2, Grid.CELL_SIZE/2)\n```\n\nNote: Create placeholder sprites if assets don't exist yet.",
      "priority": "medium",
      "dependencies": [
        2,
        3,
        5
      ],
      "status": "pending"
    },
    {
      "id": 9,
      "title": "UI - Score & Game Over Display",
      "description": "[code] Display live score, high score, and game-over message with restart prompt",
      "details": "In Main.tscn, add Label nodes:\n- `ScoreLabel` (top-left): shows \"Score: {score}\" during play\n- `GameOverLabel` (center): hidden during play, shows \"GAME OVER\\nScore: {score}\\nHigh Score: {high_score}\\nPress any key to restart\" when dead\n\nIn `scripts/game_controller.gd`:\n- Reference labels: `@onready var score_label: Label = $ScoreLabel`, `@onready var game_over_label: Label = $GameOverLabel`\n- `func update_ui()`:\n  - `score_label.text = \"Score: %d\" % score`\n  - `score_label.visible = (state == GameState.PLAYING)`\n  - `game_over_label.visible = (state == GameState.GAME_OVER)`\n  - If game over: `game_over_label.text = \"GAME OVER\\nScore: %d\\nHigh Score: %d\\nPress any key to restart\" % [score, high_score]`\n- Call `update_ui()` in `_on_tick()`, `game_over()`, and `reset_game()`\n\nPseudo-code:\n```gdscript\nfunc update_ui():\n    score_label.text = \"Score: %d\" % score\n    score_label.visible = (state == GameState.PLAYING)\n    game_over_label.visible = (state == GameState.GAME_OVER)\n    if state == GameState.GAME_OVER:\n        game_over_label.text = \"GAME OVER\\nScore: %d\\nHigh Score: %d\\nPress any key\" % [score, high_score]\n\nfunc game_over():\n    state = GameState.GAME_OVER\n    tick_timer.stop()\n    high_score = max(high_score, score)\n    update_ui()\n```",
      "priority": "medium",
      "dependencies": [
        3
      ],
      "status": "pending"
    },
    {
      "id": 10,
      "title": "Audio - Eat & Death Sounds",
      "description": "[audio] Play sound effects for eating food and dying using AudioStreamPlayer",
      "details": "In Main.tscn, add two AudioStreamPlayer nodes:\n- `EatSound`: load `source/audio/eat_food.wav`\n- `DeathSound`: load `source/audio/death.wav`\n\nIn `scripts/game_controller.gd`:\n- Reference players: `@onready var eat_sound: AudioStreamPlayer = $EatSound`, `@onready var death_sound: AudioStreamPlayer = $DeathSound`\n- In `_on_tick()` when food is eaten: `eat_sound.play()`\n- In `game_over()`: `death_sound.play()`\n\nPseudo-code:\n```gdscript\nfunc _on_tick():\n    # ... movement & collision ...\n    if snake.get_head() == food_position:\n        snake.grow()\n        score += 1\n        eat_sound.play()\n        spawn_food()\n\nfunc game_over():\n    death_sound.play()\n    state = GameState.GAME_OVER\n    # ...\n```\n\nNote: Create placeholder audio files if `source/audio/` doesn't exist.",
      "priority": "low",
      "dependencies": [
        3,
        5,
        6
      ],
      "status": "pending"
    },
    {
      "id": 11,
      "title": "Golden Path Integration Test",
      "description": "[code] Create an integration test that simulates a complete game session from start to game over",
      "details": "Create `test/golden_path_test.gd` extending GdUnitTestSuite:\n- Test simulates: game start → input commands → eating food → growing → collision → game over → restart\n- Use GdUnitSceneRunner to run Main.tscn:\n  ```gdscript\n  var runner := scene_runner(\"res://Main.tscn\")\n  var controller := runner.get_property(\"game_controller\")\n  ```\n- Simulate inputs by directly calling controller methods or injecting InputEvents\n- Assert: initial snake length == 3, score == 0\n- Simulate movement toward food, assert snake grows and score increments\n- Simulate collision with wall or self, assert state == GAME_OVER\n- Simulate restart input, assert score resets and state == PLAYING\n\nPseudo-code:\n```gdscript\nextends GdUnitTestSuite\n\nfunc test_golden_path_full_game_cycle() -> void:\n    var runner := scene_runner(\"res://Main.tscn\")\n    var controller = runner.get_property(\".\")\n    \n    # Verify initial state\n    assert_int(controller.snake.body.size()).is_equal(3)\n    assert_int(controller.score).is_equal(0)\n    \n    # Simulate eating food\n    controller.snake.direction = Vector2i.RIGHT\n    var initial_length := controller.snake.body.size()\n    # ... manually trigger tick, food collision ...\n    assert_int(controller.snake.body.size()).is_greater(initial_length)\n    assert_int(controller.score).is_greater(0)\n    \n    # Simulate wall collision\n    controller.snake.body[0] = Vector2i(0, 5)  # move to wall\n    controller._on_tick()\n    assert_that(controller.state).is_equal(controller.GameState.GAME_OVER)\n    \n    # Simulate restart\n    controller.reset_game()\n    assert_int(controller.score).is_equal(0)\n    assert_that(controller.state).is_equal(controller.GameState.PLAYING)\n```",
      "testStrategy": "Integration test covering full game loop: movement, eating, collision, game over, restart",
      "priority": "medium",
      "dependencies": [
        3,
        4,
        5,
        6
      ],
      "status": "pending"
    }
  ],
  "metadata": {
    "projectName": "Snake Game (Godot 4)",
    "totalTasks": 11,
    "sourceFile": "PRD provided by user",
    "generatedAt": "2026-05-23"
  }
}
```
