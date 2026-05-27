# parse-systems Prompt Trace

## Metadata
- **timestamp:** 2026-05-27T07:33:08.110Z
- **research:** false
- **append:** false
- **nextId:** 1
- **variant:** default

## System Prompt

```
You are an expert software architect. Parse the provided systems design document and generate a structured list of development tasks — exactly one task per `###` section heading found in the document.

Each task represents one complete system. Each task MUST include a populated `subtasks` array with thin, testable vertical slices — implementation steps that can each be code-reviewed and verified in isolation.

STRICT RULES:
1. Generate EXACTLY ONE task per `###` section. Do NOT add, remove, or merge sections.
2. Top-level task IDs are sequential integers starting from 1.
3. Top-level `dependencies` reference other top-level task IDs (absolute values in the same ID sequence).
4. Subtask `id` values are 1-based integers WITHIN their parent, resetting per parent (parent-local).
5. Subtask `dependencies` reference SIBLING subtask IDs only (parent-local; e.g., subtask 3 depends on [1, 2] within the same system).
6. Subtasks have NO `priority` field.
7. Set `status` to `"pending"` for all tasks and subtasks.
8. Set `priority` to `"medium"` for all top-level tasks.

TASK JSON STRUCTURE:
{
	"id": <sequential integer starting from 1>,
	"title": <system name from ### heading>,
	"description": <one sentence: what this system does>,
	"details": <implementation guidance: key interfaces, patterns, entry points, file/module layout>,
	"priority": "medium",
	"dependencies": [<top-level task IDs this depends on — empty [] if none>],
	"status": "pending",
	"subtasks": [
		{
			"id": <1-based integer within this parent>,
			"title": <name of this implementation slice>,
			"description": <one sentence: what this slice delivers>,
			"details": <specific steps, file names, function signatures, interfaces to implement>,
			"status": "pending",
			"dependencies": [<parent-local sibling subtask IDs — empty [] for the first slice>]
		}
	]
}

Return a JSON object with:
- "tasks": array of task objects (exactly one per ### section, in document order)
- "metadata": null
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

Parse this systems design document into tasks (one per `###` section), starting top-level task IDs from 1.

Document path: C:\GameDev\SnakeGodotTaskmaster\.taskmaster\docs\systems.md
Document content:
# Game Systems Architecture: Snake

## Source
Derived from `thoughts/shared/game-design/2026-05-27-ENG-snake.md` — a classic single-player endless Snake: a continuously grid-stepping snake on a 25×25 walled arena eats apples to grow by one segment each (+1 score), dying on contact with the outer wall or its own tail, chasing a persisted high score with no win state.

## Architecture Philosophy
All game rules live in pure, stateless modules (`SnakeLogic`, `AppleLogic`) that operate on a single plain-data `GameState` object passed by reference and mutate it in place — no module owns a private copy of game state. The Godot 4 nodes (`Game`, `BoardView`, HUD/screens) are thin shells: they own only what the engine forces them to (a `Timer`, input capture, rendering, the scene tree, file IO) and translate engine events into calls on the pure modules. Because the logic never touches the scene tree, input polling, or rendering, it compiles and unit-tests headlessly under gdUnit4, and the Godot-specific surface stays small and obvious.

## Technical Challenges & Considerations

- **Timing & update model.** Movement is a fixed **125 ms tick (8 tiles/s)**, frame-rate-independent and constant for the whole run. Most direct Godot 4 approach: a single `Timer` node (`wait_time = 0.125`, `one_shot = false`) owned by the `Game` shell. Its `timeout` signal is the authoritative game clock — one tick advances the simulation exactly one step. Pause = `timer.stop()`; resume = `timer.start()`. No `_process` accumulator is needed because the rate never varies; rendering is decoupled (the view redraws on tick, not per frame).

- **Coordinate systems.** Logic works purely in **grid space** (`Vector2i`, columns/rows `0..24`); the engine never leaks in. Pixel conversion happens only in `BoardView`: `pixel = BOARD_ORIGIN + tile * TILE_PX` with `TILE_PX = 16`. The 400×400 playfield plus a one-tile border is positioned inside the 640×480 viewport with the HUD above it. `2d/snap/*` and integer stretch are already enabled in `project.godot`, so pixel-art alignment is automatic.

- **State representation.** The snake is an `Array[Vector2i]` with the **head at index 0** and tail at the end — moving is "prepend new head, pop tail"; growing is "prepend new head, skip the pop." The apple is a single `Vector2i` (sentinel `Vector2i(-1, -1)` = none). This is the simplest structure that supports O(length) collision and ordered redraw; at 625 max tiles a linear `has()` check is trivially fast, so **no occupancy Dictionary/set is introduced** (rejected as premature optimization).

- **Input handling.** Event-driven via `_unhandled_input` in the `Game` shell using **InputMap actions** (`move_up/down/left/right`, `pause`, `confirm`) — these must be added to `project.godot` (Arrows + WASD for movement; Esc/P for pause; Enter/Space for confirm). Mapped directions are pushed into a small FIFO **`InputBuffer`** (cap 2) so a quick double-turn within one tick isn't lost. Each tick the `Game` consumes one *valid* buffered turn; "at most one direction change per tick" falls out of consuming one entry per `timeout`.

- **The 180° reversal trap.** Rejecting a direction equal to the negation of the snake's *current heading* is not enough: with two turns buffered in one tick (e.g. heading Right, queue `[Up, Down]`), naïvely applying both would reverse Up→Down into the neck. Solution: validation happens at **consume time against the last committed direction**, not at push time. `InputBuffer.consume(current_dir)` pops and discards entries until it finds one that is a legal turn relative to `current_dir` (using `SnakeLogic.is_valid_turn`), returning `current_dir` unchanged if none qualifies. This single rule kills both same-frame and cross-frame reversals.

- **Collision / overlap detection.** Pure **data lookup**, never physics nodes (no `Area2D`/`Body`). `SnakeLogic.is_lethal(state, head)` returns true if `head` is outside `[0, bounds-1]` (wall) or occupies a body tile. **Tail-vacate edge case:** when not growing this tick, the current tail tile is excluded from the self-collision check because it will move away the same tick (the classic "chase your own tail end" legal move); when growing, the tail stays and is lethal. This is deterministic and headlessly testable, which physics overlap would not be.

- **Game state machine.** Four screen states — `TITLE → PLAYING ⇄ PAUSED → GAME_OVER → PLAYING`. A simple **enum-based FSM** in the `Game` shell is the most direct fit; a pushdown automaton was considered for PAUSED-over-PLAYING but is overkill for one freeze state — pause simply stops the timer and shows an overlay, and resume returns to `PLAYING`. `Game` owns the current state and gates input and the timer on it.

- **Persistence.** Only the best score persists. Stored via **`ConfigFile`** to `user://snake.cfg` (`[scores] best=<int>`) — the cleanest Godot 4 idiom for a single value, robust to a missing file on first run. Loaded once at boot (shown on the title screen); saved at game over only when the run beats the stored best. File IO lives in the `ScoreStore` service.

- **Spawning / lifecycle.** Apple respawn picks a uniformly random unoccupied tile via an injected `RandomNumberGenerator` (seedable → deterministic tests). **No object pooling and no per-segment nodes:** snake segments and the apple are data, drawn by one `_draw()` pass, so there is zero node churn as the snake grows.

- **Determinism & testability.** `SnakeLogic`, `AppleLogic`, `InputBuffer`, and the `GameState` factory are pure/data and fully unit-tested. RNG is passed in (never global) so apple placement is reproducible. Per project guidance, the engine-glue shells (`Game`, `BoardView`, HUD, `ScoreStore` IO) are not unit-tested.

- **Edge cases.** (1) Reversal input ignored (snake length ≥ 3 always). (2) **Board full** — `AppleLogic.spawn` returns the no-apple sentinel when no free tile exists; play continues until the unavoidable self-collision (the GDD's "fill the board" skill ceiling). (3) First tick: snake starts heading Right and moves on the first `timeout`. (4) Restart resets the `GameState` in place rather than reallocating. (5) Simultaneous eat-and-die cannot occur (apple never spawns on the snake).

## Shared Data Model

### GameState
- **Purpose:** The entire mutable state of one run — the single object every logic module reads and mutates by reference.
- **Fields:**
  - `snake: Array[Vector2i]` — body tiles, head at index 0, tail last.
  - `direction: Vector2i` — current committed heading (one of `Vector2i.RIGHT/LEFT/UP/DOWN`).
  - `apple: Vector2i` — apple tile, or `Vector2i(-1, -1)` when none.
  - `grow_pending: int` — segments still owed (incremented on eat; while > 0 a tick skips the tail-pop and decrements).
  - `score: int` — apples eaten this run.
  - `alive: bool` — false once a lethal collision is detected.
  - `bounds: Vector2i` — grid dimensions `(25, 25)`, carried in state so logic is self-contained and testable at other sizes.
- **Lifecycle:** Created by `GameState.new_game()` at run start (snake = 3 tiles near center heading Right, `score = 0`, `alive = true`, `grow_pending = 0`, apple unset). Mutated each tick by `SnakeLogic.advance` and on eat by `AppleLogic.spawn`. Reset in place on restart.

### Game configuration (constants)
- **Purpose:** Fixed tuning values from the GDD, shared by logic and view.
- **Fields:** `GRID = Vector2i(25, 25)`, `TILE_PX = 16`, `TICK_SECONDS = 0.125`, `START_LENGTH = 3`, `BOARD_ORIGIN: Vector2` (pixel offset of tile (0,0) inside the viewport).
- **Lifecycle:** Compile-time `const`s; never mutated. Logic constants (`GRID`, `START_LENGTH`) feed `GameState.new_game`; pixel constants (`TILE_PX`, `BOARD_ORIGIN`) are used only by `BoardView`.

## Systems

### GameState
- **Goal:** Hold the run's state as plain data and provide a clean factory/reset.
- **Type:** data model (`RefCounted`).
- **Inputs:** grid bounds and start length at construction.
- **Outputs / mutations:** is the object every other system mutates.
- **Key functions:** `static func new_game(bounds: Vector2i, start_length: int) -> GameState`; `func reset(bounds: Vector2i, start_length: int) -> void`.
- **Dependencies:** none.
- **Godot 4 mapping:** none — pure data class (`class_name GameState extends RefCounted`).
- **State note:** It *is* the state; held by the `Game` shell, passed by reference into all logic.

### SnakeLogic
- **Goal:** Own all snake movement, turning, and collision rules.
- **Type:** pure/stateless logic (static funcs).
- **Inputs:** a `GameState` (and a candidate direction for turn validation).
- **Outputs / mutations:** mutates `state.snake`, `state.direction`, `state.grow_pending`, `state.score`, `state.alive`; returns a `StepResult`.
- **Key functions:**
  - `enum StepResult { MOVED, ATE, DIED }`
  - `static func is_valid_turn(current: Vector2i, next: Vector2i) -> bool` — true if `next` is axis-aligned, non-zero, and `next != -current`.
  - `static func next_head(state: GameState) -> Vector2i`
  - `static func is_lethal(state: GameState, head: Vector2i) -> bool` — wall bounds + self-collision, excluding the tail tile when `grow_pending == 0`.
  - `static func advance(state: GameState) -> int` — compute next head; if lethal set `alive = false` and return `DIED`; else prepend head, and if it equals `state.apple` (`score += 1`, `grow_pending += 1`, clear apple) return `ATE`, otherwise pop tail (or decrement `grow_pending`) and return `MOVED`.
- **Dependencies:** `GameState`.
- **Godot 4 mapping:** none — pure module (`class_name SnakeLogic`).
- **State note:** stateless.

### AppleLogic
- **Goal:** Place the single apple on a random unoccupied tile.
- **Type:** pure/stateless logic (static funcs).
- **Inputs:** a `GameState` and a `RandomNumberGenerator`.
- **Outputs / mutations:** sets `state.apple`; returns the chosen tile (sentinel `Vector2i(-1, -1)` if the board is full).
- **Key functions:** `static func spawn(state: GameState, rng: RandomNumberGenerator) -> Vector2i` — build the free-cell list (tiles in `bounds` not in `snake`), pick one with `rng.randi_range`, assign to `state.apple`.
- **Dependencies:** `GameState`.
- **Godot 4 mapping:** none — pure module (`class_name AppleLogic`). RNG is injected, not global, for deterministic tests.
- **State note:** stateless; randomness is externalized into the passed RNG.

### InputBuffer
- **Goal:** Queue requested turns and yield at most one legal turn per tick.
- **Type:** logic (`RefCounted`, unit-testable; holds only a transient queue).
- **Inputs:** directions pushed by the `Game` shell; current heading at consume time.
- **Outputs / mutations:** mutates its internal queue; returns the next valid direction.
- **Key functions:** `func push(dir: Vector2i) -> void` (caps the queue at 2, ignoring an immediate duplicate of the tail); `func consume(current_dir: Vector2i) -> Vector2i` (pops and discards entries until one satisfies `SnakeLogic.is_valid_turn(current_dir, e)`, returning it, else returns `current_dir`); `func clear() -> void`.
- **Dependencies:** `SnakeLogic.is_valid_turn`.
- **Godot 4 mapping:** none — plain class (`class_name InputBuffer extends RefCounted`); the `Game` shell does the engine-level input capture and feeds it.
- **State note:** holds a short FIFO of pending directions — inherently a timing buffer between async input events and synchronous ticks, so it cannot be a pure function; kept tiny and clearable on restart.

### ScoreStore
- **Goal:** Load and persist the best score across sessions.
- **Type:** autoload/service (static funcs; touches the filesystem).
- **Inputs:** an int to save; nothing to load.
- **Outputs / mutations:** reads/writes `user://snake.cfg`.
- **Key functions:** `static func load_best() -> int` (returns 0 if absent); `static func save_best(score: int) -> void`.
- **Dependencies:** none (Godot `ConfigFile`).
- **Godot 4 mapping:** `class_name ScoreStore` static utility (no autoload registration needed); uses `ConfigFile` against `user://`.
- **State note:** the only persistent state is the file itself; no in-memory caching beyond what `Game` holds.

### Game
- **Goal:** Orchestrate one frame/tick, own the FSM, the tick clock, input capture, and wire logic results to view/HUD/persistence.
- **Type:** stateful node shell.
- **Inputs:** engine events — `Timer.timeout`, `_unhandled_input`.
- **Outputs / mutations:** drives `GameState` via the logic modules; tells `BoardView` to redraw; updates HUD; calls `ScoreStore`.
- **Key functions:** `_unhandled_input(event)` (map actions → `InputBuffer.push` / pause / confirm); `_on_tick()` (PLAYING only: commit `state.direction = InputBuffer.consume(state.direction)`, call `SnakeLogic.advance`, branch on `StepResult`); `_set_state(new_state)` (FSM transitions: start/stop timer, toggle screen visibility).
- **Dependencies:** `GameState`, `SnakeLogic`, `AppleLogic`, `InputBuffer`, `ScoreStore`, `BoardView`, HUD/screens.
- **Godot 4 mapping:** root `Node2D` (`game.gd`); owns child `Timer` (`timeout`), `BoardView`, and the UI `CanvasLayer`s; holds the `RandomNumberGenerator`. Emits/handles UI updates via direct calls or signals (`score_changed`, `game_over`).
- **State note:** owns engine-mandated state only — the `Timer`, the current FSM enum, the `RandomNumberGenerator`, the `InputBuffer`, and a reference to the `GameState` data object. All *rules* are delegated to the pure modules.

### BoardView
- **Goal:** Render the current `GameState` as pixel art and play eat/death flashes.
- **Type:** stateful node shell (rendering only).
- **Inputs:** a reference to the `GameState`; a redraw request per tick.
- **Outputs / mutations:** draws to screen; mutates only a small visual flash flag/timer.
- **Key functions:** `_draw()` (floor, border walls, body segments, distinct head, apple via `draw_texture`); `func refresh() -> void` (`queue_redraw()`); `func flash_eat() -> void` / `func flash_death() -> void`.
- **Dependencies:** `GameState` (read-only), `Game` configuration constants, sprite textures.
- **Godot 4 mapping:** `Node2D` (`board_view.gd`) using `_draw()` + `queue_redraw()`; preloads `res://sprites/*.png`. Sits under `Game`, positioned at `BOARD_ORIGIN`.
- **State note:** holds only transient flash timing; reads game state, never mutates it.

### HUD & Screens (TitleScreen, GameOverScreen, PauseOverlay, ScoreHUD)
- **Goal:** Present score/high-score and the title/game-over/pause UI; relay confirm/pause intent (handled by `Game`).
- **Type:** stateful node shells (UI).
- **Inputs:** values pushed from `Game` (current score, best score, "new best" flag).
- **Outputs / mutations:** update `Label` text and visibility.
- **Key functions:** `func set_scores(score: int, best: int) -> void`; `func show_new_best(is_best: bool) -> void`.
- **Dependencies:** none beyond values from `Game`.
- **Godot 4 mapping:** `CanvasLayer` + `Control`/`Label` nodes; visibility toggled by `Game._set_state`.
- **State note:** display state only.

## System Interaction & Data Flow

**One PLAYING tick (`Timer.timeout` → `Game._on_tick`):**
1. `Game` commits the turn: `state.direction = input_buffer.consume(state.direction)` (one legal turn, or unchanged).
2. `Game` calls `SnakeLogic.advance(state)`:
   - reads `direction`, computes `next_head`, runs `is_lethal` (wall + self, tail-vacate aware);
   - mutates `state` in place and returns `MOVED` / `ATE` / `DIED`.
3. `Game` branches on the result:
   - **MOVED** → `board_view.refresh()`.
   - **ATE** → `AppleLogic.spawn(state, rng)`; `hud.set_scores(state.score, best)`; `board_view.flash_eat()`; `board_view.refresh()`.
   - **DIED** → `timer.stop()`; if `state.score > best` → `best = state.score`, `ScoreStore.save_best(best)`, mark new-best; `board_view.flash_death()`; transition `→ GAME_OVER`.

**Input (async, `_unhandled_input`):** movement actions → `input_buffer.push(dir)`; `pause` toggles `PLAYING ⇄ PAUSED` (stop/start timer, toggle overlay); `confirm` starts from TITLE or restarts from GAME_OVER.

**Start / restart:** `Game` builds (or `reset`s) the `GameState`, clears the `InputBuffer`, `AppleLogic.spawn(state, rng)` for the first apple, `hud.set_scores`, `board_view.refresh()`, `timer.start()`, state `→ PLAYING`.

**Render cadence:** `BoardView` redraws only on `refresh()` (per tick / on transition), not every frame — state changes are tick-quantized.

## Game State Machine
States and legal transitions (owned by `Game`, enum FSM):

- `TITLE` —`confirm`→ `PLAYING` (new game).
- `PLAYING` —`pause`→ `PAUSED`; —snake dies→ `GAME_OVER`.
- `PAUSED` —`pause`/`confirm`→ `PLAYING` (resume; timer restarts).
- `GAME_OVER` —`confirm`→ `PLAYING` (restart).

Each transition gates the tick `Timer` (running only in `PLAYING`) and toggles the matching `CanvasLayer` overlay's visibility. Pause is a freeze (timer stopped, state preserved), not a teardown.

## Godot 4 Scene Tree / Node Layout
```
Main (Node2D, game.gd)            # Game shell: FSM, RNG, GameState, InputBuffer
├── TickTimer (Timer)             # wait_time=0.125, one_shot=false → _on_tick
├── BoardView (Node2D, board_view.gd)   # _draw() renders GameState at BOARD_ORIGIN
├── ScoreHUD (CanvasLayer, hud.gd)      # current + best score labels
├── TitleScreen (CanvasLayer, title_screen.gd)
├── PauseOverlay (CanvasLayer, pause_overlay.gd)
└── GameOverScreen (CanvasLayer, game_over_screen.gd)
```
Pure modules (`GameState`, `SnakeLogic`, `AppleLogic`, `InputBuffer`, `ScoreStore`) attach to **no node** — they are `class_name` scripts the shells `preload`/reference. `Main.tscn` (already the project's `run/main_scene`) is repurposed as the `Game` root.

## File / Module Layout
Pure logic (no node, each gets a `_test.gd`):
- `res://scripts/game_state.gd` — `class_name GameState` → `test/game_state_test.gd`
- `res://scripts/snake_logic.gd` — `class_name SnakeLogic` → `test/snake_logic_test.gd`
- `res://scripts/apple_logic.gd` — `class_name AppleLogic` → `test/apple_logic_test.gd`
- `res://scripts/input_buffer.gd` — `class_name InputBuffer` → `test/input_buffer_test.gd`

Service (file IO — not unit-tested per project guidance):
- `res://scripts/score_store.gd` — `class_name ScoreStore`

Node shells (not unit-tested):
- `res://scripts/game.gd` (attached to `Main.tscn` root)
- `res://scripts/board_view.gd`
- `res://scripts/hud.gd`, `title_screen.gd`, `pause_overlay.gd`, `game_over_screen.gd`

Existing assets reused: `res://sprites/{player_head,player_body,food,wall_tile,floor_tile}.png`.

Config touch-up: add the `[input]` action map (`move_up/down/left/right`, `pause`, `confirm`) to `project.godot`. (Run `godot --headless --path snaketaskmaster --import` after creating files.)

## Vertical Slice Definition
From the title screen (showing the persisted high score), the player presses Enter/Space to start. A 3-segment snake begins moving Right at 8 tiles/s on a 25×25 walled arena; Arrows/WASD steer it (no 180° reversal), Esc/P pauses. Eating the apple grows the snake by one, adds +1 to the on-screen score, briefly flashes, and respawns a new apple on a free tile. Hitting the wall or its own tail flashes the snake and shows the game-over screen with final score and high score ("New Best!" when beaten); Enter/Space restarts. This is the full MVP loop end to end, silent, in pixel art.

## Out of Scope
Deferred by the GDD and deliberately not architected here: **audio** (SFX + chiptune — note `audio/death.wav` and `audio/eat_food.wav` exist but stay unused in MVP), **bonus/timed food**, **interior maze walls or selectable arenas**, and a **speed-ramp difficulty mode**. Excluded non-goals: multiplayer/versus, enemy or AI snakes, procedurally generated levels, and mobile/touch input. The single fixed arena, constant tick rate, single apple, and one life keep the data model and systems intentionally minimal — no level manager, difficulty curve, entity pool, or input abstraction beyond the buffer is introduced.


IMPORTANT: Your response must be a JSON object with a "tasks" property (array with one entry per ### section) and "metadata" set to null.
```

## LLM Response

```json
{
  "tasks": [
    {
      "id": 1,
      "title": "GameState",
      "description": "Hold the run's state as plain data and provide a clean factory/reset.",
      "details": "Create a RefCounted class (res://scripts/game_state.gd) with fields: snake (Array[Vector2i]), direction (Vector2i), apple (Vector2i), grow_pending (int), score (int), alive (bool), bounds (Vector2i). Provide static func new_game(bounds, start_length) and func reset(bounds, start_length). This is pure data with no engine dependencies.",
      "priority": "medium",
      "dependencies": [],
      "status": "pending",
      "subtasks": [
        {
          "id": 1,
          "title": "Define GameState class structure",
          "description": "Create game_state.gd with all state fields as typed properties.",
          "details": "Create res://scripts/game_state.gd. Declare class_name GameState extends RefCounted. Add typed fields: snake: Array[Vector2i], direction: Vector2i, apple: Vector2i, grow_pending: int, score: int, alive: bool, bounds: Vector2i. No initialization logic yet.",
          "status": "pending",
          "dependencies": []
        },
        {
          "id": 2,
          "title": "Implement new_game factory",
          "description": "Add static factory function to initialize a fresh game state.",
          "details": "Write static func new_game(bounds: Vector2i, start_length: int) -> GameState. Create instance, set bounds, alive=true, score=0, grow_pending=0, direction=Vector2i.RIGHT, apple=Vector2i(-1,-1). Initialize snake array with start_length tiles near center heading right (e.g., for 3 tiles at (12,12): [(12,12), (11,12), (10,12)]).",
          "status": "pending",
          "dependencies": [
            1
          ]
        },
        {
          "id": 3,
          "title": "Implement reset method",
          "description": "Add reset function to reinitialize state in place.",
          "details": "Write func reset(bounds: Vector2i, start_length: int) -> void. Clear snake array, then repopulate with same logic as new_game. Reset all fields: alive=true, score=0, grow_pending=0, direction=Vector2i.RIGHT, apple=Vector2i(-1,-1). This avoids reallocation on restart.",
          "status": "pending",
          "dependencies": [
            2
          ]
        },
        {
          "id": 4,
          "title": "Create GameState unit tests",
          "description": "Write comprehensive test suite for GameState factory and reset.",
          "details": "Create res://test/game_state_test.gd extending GdUnitTestSuite. Test new_game: verify bounds, start_length translates to correct snake array (head at [0], tail at end), direction=RIGHT, score=0, alive=true, apple sentinel. Test reset: create state, mutate fields, call reset, verify all fields return to initial values. Test edge cases: start_length=1, different bounds.",
          "status": "pending",
          "dependencies": [
            3
          ]
        }
      ]
    },
    {
      "id": 2,
      "title": "SnakeLogic",
      "description": "Own all snake movement, turning, and collision rules.",
      "details": "Create a pure/stateless logic module (res://scripts/snake_logic.gd) with static functions. Define enum StepResult { MOVED, ATE, DIED }. Implement is_valid_turn, next_head, is_lethal, advance. Key rule: tail-vacate edge case (exclude tail from self-collision when grow_pending==0). Mutates GameState in place, returns StepResult.",
      "priority": "medium",
      "dependencies": [
        1
      ],
      "status": "pending",
      "subtasks": [
        {
          "id": 1,
          "title": "Define SnakeLogic class and StepResult enum",
          "description": "Create snake_logic.gd with class declaration and result enum.",
          "details": "Create res://scripts/snake_logic.gd. Declare class_name SnakeLogic (no extends, pure static). Define enum StepResult { MOVED, ATE, DIED }. Preload GameState for type hints.",
          "status": "pending",
          "dependencies": []
        },
        {
          "id": 2,
          "title": "Implement is_valid_turn",
          "description": "Validate direction changes to prevent 180° reversals.",
          "details": "Write static func is_valid_turn(current: Vector2i, next: Vector2i) -> bool. Return false if next is zero-length, not axis-aligned (both x and y non-zero), or equals -current (reversal). Return true otherwise. This is the core anti-reversal logic consumed by InputBuffer.",
          "status": "pending",
          "dependencies": [
            1
          ]
        },
        {
          "id": 3,
          "title": "Implement next_head helper",
          "description": "Compute the new head position based on current direction.",
          "details": "Write static func next_head(state: GameState) -> Vector2i. Return state.snake[0] + state.direction (head tile shifted by the direction vector).",
          "status": "pending",
          "dependencies": [
            1
          ]
        },
        {
          "id": 4,
          "title": "Implement is_lethal collision detection",
          "description": "Check wall bounds and self-collision with tail-vacate awareness.",
          "details": "Write static func is_lethal(state: GameState, head: Vector2i) -> bool. Return true if head.x < 0 or head.x >= state.bounds.x or head.y < 0 or head.y >= state.bounds.y (wall). Then check self-collision: if grow_pending > 0, check head against all snake tiles; else exclude tail (state.snake[-1]) because it will vacate. Return true if head in body (excluding vacated tail).",
          "status": "pending",
          "dependencies": [
            3
          ]
        },
        {
          "id": 5,
          "title": "Implement advance simulation step",
          "description": "Execute one tick: move snake, detect collisions, handle eating.",
          "details": "Write static func advance(state: GameState) -> int (StepResult). Call next_head(state) to get new_head. If is_lethal(state, new_head): set state.alive=false, return DIED. Else: prepend new_head to state.snake. If new_head == state.apple: increment state.score and state.grow_pending, set state.apple=Vector2i(-1,-1), return ATE. Else: if grow_pending > 0 decrement it, else pop state.snake tail. Return MOVED.",
          "status": "pending",
          "dependencies": [
            4
          ]
        },
        {
          "id": 6,
          "title": "Create SnakeLogic unit tests",
          "description": "Write comprehensive test suite for all SnakeLogic functions.",
          "details": "Create res://test/snake_logic_test.gd extending GdUnitTestSuite. Test is_valid_turn: valid cardinal directions, reject reversals, reject diagonal/zero. Test next_head: verify head + direction. Test is_lethal: wall bounds (all 4 edges), self-collision with tail-vacate (grow_pending=0 allows tail tile, >0 forbids it). Test advance: MOVED (normal step), ATE (head==apple increments score/grow_pending), DIED (wall + self), multi-step growth (grow_pending decrements without tail pop).",
          "status": "pending",
          "dependencies": [
            5
          ]
        }
      ]
    },
    {
      "id": 3,
      "title": "AppleLogic",
      "description": "Place the single apple on a random unoccupied tile.",
      "details": "Create a pure/stateless logic module (res://scripts/apple_logic.gd) with static spawn function. Takes GameState and RandomNumberGenerator (injected for deterministic tests). Builds free-cell list (all tiles in bounds not occupied by snake), picks one uniformly at random, assigns to state.apple, returns chosen tile. Returns sentinel Vector2i(-1,-1) if board is full.",
      "priority": "medium",
      "dependencies": [
        1
      ],
      "status": "pending",
      "subtasks": [
        {
          "id": 1,
          "title": "Define AppleLogic class structure",
          "description": "Create apple_logic.gd with class declaration.",
          "details": "Create res://scripts/apple_logic.gd. Declare class_name AppleLogic (no extends, pure static). Preload GameState for type hints.",
          "status": "pending",
          "dependencies": []
        },
        {
          "id": 2,
          "title": "Implement spawn function",
          "description": "Generate apple position on a random unoccupied tile.",
          "details": "Write static func spawn(state: GameState, rng: RandomNumberGenerator) -> Vector2i. Build free_tiles array: iterate all tiles (x in 0..<bounds.x, y in 0..<bounds.y), append tile if not in state.snake. If free_tiles is empty, set state.apple=Vector2i(-1,-1) and return it (board full). Else: pick index = rng.randi_range(0, free_tiles.size()-1), set state.apple = free_tiles[index], return state.apple.",
          "status": "pending",
          "dependencies": [
            1
          ]
        },
        {
          "id": 3,
          "title": "Create AppleLogic unit tests",
          "description": "Write test suite for apple spawning logic.",
          "details": "Create res://test/apple_logic_test.gd extending GdUnitTestSuite. Test spawn with seeded RNG: verify apple is unoccupied, verify determinism (same seed produces same tile). Test board-full edge case: create state with snake filling all but one tile, verify spawn picks that tile; fill entire board, verify spawn returns sentinel Vector2i(-1,-1) and state.apple is set to sentinel. Test multiple spawns produce different tiles (with different seeds).",
          "status": "pending",
          "dependencies": [
            2
          ]
        }
      ]
    },
    {
      "id": 4,
      "title": "InputBuffer",
      "description": "Queue requested turns and yield at most one legal turn per tick.",
      "details": "Create a RefCounted class (res://scripts/input_buffer.gd) holding a small FIFO (Array, capped at 2). Provide push(dir) to enqueue directions (reject immediate duplicates, cap size). Provide consume(current_dir) that pops and discards entries until one satisfies SnakeLogic.is_valid_turn, returning it or current_dir if none. Provide clear().",
      "priority": "medium",
      "dependencies": [
        2
      ],
      "status": "pending",
      "subtasks": [
        {
          "id": 1,
          "title": "Define InputBuffer class structure",
          "description": "Create input_buffer.gd with internal queue array.",
          "details": "Create res://scripts/input_buffer.gd. Declare class_name InputBuffer extends RefCounted. Add private field: var _queue: Array[Vector2i] = []. Preload SnakeLogic for is_valid_turn.",
          "status": "pending",
          "dependencies": []
        },
        {
          "id": 2,
          "title": "Implement push method",
          "description": "Enqueue direction inputs with duplicate filtering and size cap.",
          "details": "Write func push(dir: Vector2i) -> void. If _queue is not empty and _queue[-1] == dir, return early (reject duplicate). If _queue.size() >= 2, return early (cap reached). Else: _queue.append(dir).",
          "status": "pending",
          "dependencies": [
            1
          ]
        },
        {
          "id": 3,
          "title": "Implement consume method",
          "description": "Pop and validate buffered turns against current direction.",
          "details": "Write func consume(current_dir: Vector2i) -> Vector2i. While _queue is not empty: pop front entry (candidate = _queue.pop_front()). If SnakeLogic.is_valid_turn(current_dir, candidate): return candidate (and update current_dir for next iteration to prevent chained reversals within the buffer). If queue exhausted, return current_dir unchanged.",
          "status": "pending",
          "dependencies": [
            2
          ]
        },
        {
          "id": 4,
          "title": "Implement clear method",
          "description": "Reset the buffer to empty state.",
          "details": "Write func clear() -> void. Set _queue = [] (or _queue.clear()).",
          "status": "pending",
          "dependencies": [
            1
          ]
        },
        {
          "id": 5,
          "title": "Create InputBuffer unit tests",
          "description": "Write test suite for input buffering and validation logic.",
          "details": "Create res://test/input_buffer_test.gd extending GdUnitTestSuite. Test push: verify cap at 2, reject immediate duplicate (tail == new). Test consume: valid turn dequeued, invalid turn discarded and next tried, 180° reversal across two queued turns rejected (e.g., heading RIGHT, queue [UP, LEFT] → consume returns UP, not LEFT). Test clear. Test empty consume returns current_dir.",
          "status": "pending",
          "dependencies": [
            4
          ]
        }
      ]
    },
    {
      "id": 5,
      "title": "ScoreStore",
      "description": "Load and persist the best score across sessions.",
      "details": "Create a static utility class (res://scripts/score_store.gd) with load_best() -> int and save_best(score: int) -> void. Uses ConfigFile against user://snake.cfg, section [scores], key best. load_best returns 0 if file/key missing (first run). No autoload registration needed, just static funcs.",
      "priority": "medium",
      "dependencies": [],
      "status": "pending",
      "subtasks": [
        {
          "id": 1,
          "title": "Define ScoreStore class structure",
          "description": "Create score_store.gd with class declaration.",
          "details": "Create res://scripts/score_store.gd. Declare class_name ScoreStore (no extends, pure static). Define constants: const CONFIG_PATH = \"user://snake.cfg\", const SECTION = \"scores\", const KEY = \"best\".",
          "status": "pending",
          "dependencies": []
        },
        {
          "id": 2,
          "title": "Implement load_best function",
          "description": "Read persisted high score from config file.",
          "details": "Write static func load_best() -> int. Create ConfigFile instance. Call load(CONFIG_PATH); if error != OK return 0 (file doesn't exist on first run). Return get_value(SECTION, KEY, 0) (default 0 if key missing).",
          "status": "pending",
          "dependencies": [
            1
          ]
        },
        {
          "id": 3,
          "title": "Implement save_best function",
          "description": "Persist new high score to config file.",
          "details": "Write static func save_best(score: int) -> void. Create ConfigFile instance. Call load(CONFIG_PATH) (ignore error if file doesn't exist). Call set_value(SECTION, KEY, score). Call save(CONFIG_PATH). No return value; errors are silent (acceptable per GDD simplicity).",
          "status": "pending",
          "dependencies": [
            1
          ]
        }
      ]
    },
    {
      "id": 6,
      "title": "Game",
      "description": "Orchestrate one frame/tick, own the FSM, the tick clock, input capture, and wire logic results to view/HUD/persistence.",
      "details": "Create the main node shell (res://scripts/game.gd attached to Main.tscn root). Own Timer, RandomNumberGenerator, GameState, InputBuffer. Implement FSM (enum: TITLE, PLAYING, PAUSED, GAME_OVER). Handle _unhandled_input (map InputMap actions to buffer/pause/confirm). Handle Timer.timeout via _on_tick: consume input, call SnakeLogic.advance, branch on StepResult (MOVED/ATE/DIED), update view/HUD, manage persistence. Functions: _set_state(new_state) for FSM transitions.",
      "priority": "medium",
      "dependencies": [
        1,
        2,
        3,
        4,
        5
      ],
      "status": "pending",
      "subtasks": [
        {
          "id": 1,
          "title": "Define Game class and FSM",
          "description": "Create game.gd with state machine and core fields.",
          "details": "Create res://scripts/game.gd. Declare extends Node2D. Define enum GameMode { TITLE, PLAYING, PAUSED, GAME_OVER }. Add fields: var _state: GameState, var _input_buffer: InputBuffer, var _rng: RandomNumberGenerator, var _current_mode: GameMode, var _best_score: int. Define constants: const GRID = Vector2i(25, 25), const START_LENGTH = 3, const TICK_SECONDS = 0.125. Preload all logic modules (GameState, SnakeLogic, AppleLogic, InputBuffer, ScoreStore).",
          "status": "pending",
          "dependencies": []
        },
        {
          "id": 2,
          "title": "Add InputMap actions to project.godot",
          "description": "Define input actions for movement, pause, and confirm.",
          "details": "Manually edit snaketaskmaster/project.godot or use Godot editor. Add [input] section with actions: move_up (W, Up Arrow), move_down (S, Down Arrow), move_left (A, Left Arrow), move_right (D, Right Arrow), pause (Esc, P), confirm (Enter, Space). Each action maps to InputEventKey with the specified keycodes and physical=false.",
          "status": "pending",
          "dependencies": []
        },
        {
          "id": 3,
          "title": "Implement _ready initialization",
          "description": "Initialize game state, RNG, input buffer, load best score.",
          "details": "Write func _ready() -> void. Create _rng = RandomNumberGenerator.new(), _input_buffer = InputBuffer.new(). Load _best_score = ScoreStore.load_best(). Get Timer child node and connect its timeout signal to _on_tick. Set _current_mode = TITLE. Do not create GameState yet (deferred to game start).",
          "status": "pending",
          "dependencies": [
            1,
            2
          ]
        },
        {
          "id": 4,
          "title": "Implement _unhandled_input for action mapping",
          "description": "Capture input events and translate to game actions.",
          "details": "Write func _unhandled_input(event: InputEvent) -> void. If _current_mode == PLAYING: check Input.is_action_just_pressed for move_up/down/left/right, map to Vector2i direction (UP=-Y, DOWN=+Y, LEFT=-X, RIGHT=+X), call _input_buffer.push(dir). If pause action: toggle PLAYING ⇄ PAUSED via _set_state. If confirm action: handle TITLE → start new game, GAME_OVER → restart, PAUSED → resume. Mark event as handled where appropriate.",
          "status": "pending",
          "dependencies": [
            3
          ]
        },
        {
          "id": 5,
          "title": "Implement _on_tick simulation step",
          "description": "Execute one game tick: consume input, advance snake, handle results.",
          "details": "Write func _on_tick() -> void. Guard: if _current_mode != PLAYING, return. Commit turn: _state.direction = _input_buffer.consume(_state.direction). Call result = SnakeLogic.advance(_state). Branch on result: MOVED → tell BoardView to refresh(). ATE → AppleLogic.spawn(_state, _rng), update HUD with new score, BoardView.flash_eat(), BoardView.refresh(). DIED → stop Timer, check if _state.score > _best_score (if so: _best_score = _state.score, ScoreStore.save_best(_best_score), flag new-best), BoardView.flash_death(), transition to GAME_OVER via _set_state.",
          "status": "pending",
          "dependencies": [
            4
          ]
        },
        {
          "id": 6,
          "title": "Implement _set_state FSM transition handler",
          "description": "Manage state transitions and update Timer/UI visibility.",
          "details": "Write func _set_state(new_mode: GameMode) -> void. Set _current_mode = new_mode. Branch on new_mode: TITLE → stop Timer, show TitleScreen, hide others. PLAYING → start Timer, hide all overlays, show ScoreHUD and BoardView. PAUSED → stop Timer, show PauseOverlay. GAME_OVER → stop Timer, show GameOverScreen with score/best/new-best flag. Each branch toggles CanvasLayer visibility for the corresponding screen nodes (references obtained via get_node or @onready).",
          "status": "pending",
          "dependencies": [
            3
          ]
        },
        {
          "id": 7,
          "title": "Implement new game start logic",
          "description": "Initialize or reset GameState and begin a new run.",
          "details": "Write func _start_new_game() -> void. If _state is null: _state = GameState.new_game(GRID, START_LENGTH). Else: _state.reset(GRID, START_LENGTH). Clear _input_buffer. Call AppleLogic.spawn(_state, _rng) for first apple. Update HUD to show score=0 and _best_score. Tell BoardView to refresh(). Call _set_state(PLAYING). This is invoked from _unhandled_input when confirm pressed in TITLE or GAME_OVER.",
          "status": "pending",
          "dependencies": [
            6
          ]
        },
        {
          "id": 8,
          "title": "Setup Main.tscn scene tree",
          "description": "Attach game.gd to Main.tscn and add Timer child node.",
          "details": "Open Main.tscn. Attach res://scripts/game.gd to the root Node2D. Add Timer child node named TickTimer, set wait_time=0.125, one_shot=false, autostart=false. Do not add other UI children yet (BoardView, HUD, screens are separate tasks). Run godot --headless --path snaketaskmaster --import after saving.",
          "status": "pending",
          "dependencies": [
            1
          ]
        }
      ]
    },
    {
      "id": 7,
      "title": "BoardView",
      "description": "Render the current GameState as pixel art and play eat/death flashes.",
      "details": "Create a Node2D shell (res://scripts/board_view.gd) with _draw() implementation. Preload sprite textures (floor_tile, wall_tile, player_head, player_body, food). Take a GameState reference from Game. Draw floor, border walls, snake segments (distinct head), apple via draw_texture. Provide refresh() → queue_redraw(). Provide flash_eat/flash_death for brief visual feedback (e.g., modulate or temporary overlay; implementation can be simple timer-based color tint).",
      "priority": "medium",
      "dependencies": [
        1,
        6
      ],
      "status": "pending",
      "subtasks": [
        {
          "id": 1,
          "title": "Define BoardView class and preload sprites",
          "description": "Create board_view.gd and load all sprite assets.",
          "details": "Create res://scripts/board_view.gd. Declare extends Node2D. Preload textures: const FLOOR = preload(\"res://sprites/floor_tile.png\"), const WALL = preload(\"res://sprites/wall_tile.png\"), const HEAD = preload(\"res://sprites/player_head.png\"), const BODY = preload(\"res://sprites/player_body.png\"), const FOOD = preload(\"res://sprites/food.png\"). Define constants: const TILE_PX = 16, const BOARD_ORIGIN = Vector2(120, 40) (example offset to center 25*16=400px board in 640x480 viewport with HUD space above). Add var _state: GameState (set by Game).",
          "status": "pending",
          "dependencies": []
        },
        {
          "id": 2,
          "title": "Implement _draw rendering",
          "description": "Draw floor tiles, walls, snake, and apple each frame.",
          "details": "Write func _draw() -> void. Loop over all tiles (x in 0..<_state.bounds.x, y in 0..<_state.bounds.y): draw_texture(FLOOR, BOARD_ORIGIN + Vector2(x, y) * TILE_PX). Draw border walls: loop x in -1..<bounds.x+1, y in -1..<bounds.y+1, if on edge (x=-1 or x=bounds.x or y=-1 or y=bounds.y): draw_texture(WALL, ...). Draw snake: for each tile in _state.snake, if index 0 draw HEAD else draw BODY at tile position. If _state.apple != Vector2i(-1,-1): draw_texture(FOOD, ...).",
          "status": "pending",
          "dependencies": [
            1
          ]
        },
        {
          "id": 3,
          "title": "Implement refresh method",
          "description": "Trigger redraw on game state changes.",
          "details": "Write func refresh() -> void. Call queue_redraw(). This is called by Game after each tick result.",
          "status": "pending",
          "dependencies": [
            2
          ]
        },
        {
          "id": 4,
          "title": "Implement flash_eat visual feedback",
          "description": "Play brief eat animation/flash effect.",
          "details": "Write func flash_eat() -> void. Simple implementation: set modulate = Color(1.2, 1.2, 1.2) for a bright flash, start a Timer (0.1s one_shot) that resets modulate to Color.WHITE on timeout. Alternatively: play a ColorRect overlay blink. Keep minimal for MVP.",
          "status": "pending",
          "dependencies": [
            3
          ]
        },
        {
          "id": 5,
          "title": "Implement flash_death visual feedback",
          "description": "Play brief death animation/flash effect.",
          "details": "Write func flash_death() -> void. Simple implementation: set modulate = Color(1.0, 0.5, 0.5) for a red flash, start a Timer (0.2s one_shot) that resets modulate on timeout. Keep minimal for MVP.",
          "status": "pending",
          "dependencies": [
            3
          ]
        },
        {
          "id": 6,
          "title": "Add BoardView to Main.tscn",
          "description": "Instantiate BoardView as child of Game in the scene tree.",
          "details": "Open Main.tscn. Add Node2D child to the Game root, attach res://scripts/board_view.gd. Set position to BOARD_ORIGIN if not handled in _draw offset. In game.gd, get reference to BoardView via @onready var _board_view: Node2D = $BoardView, and set _board_view._state = _state in _start_new_game. Run godot --headless --path snaketaskmaster --import after saving.",
          "status": "pending",
          "dependencies": [
            5
          ]
        }
      ]
    },
    {
      "id": 8,
      "title": "HUD & Screens (TitleScreen, GameOverScreen, PauseOverlay, ScoreHUD)",
      "description": "Present score/high-score and the title/game-over/pause UI; relay confirm/pause intent.",
      "details": "Create four CanvasLayer UI shells: TitleScreen (label + instructions, shown in TITLE mode), ScoreHUD (current score + best score labels, shown in PLAYING), PauseOverlay (\"Paused\" text, shown in PAUSED), GameOverScreen (final score, best score, \"New Best!\" conditional label, shown in GAME_OVER). Each has set_scores/show_new_best methods called by Game. Visibility toggled by Game._set_state.",
      "priority": "medium",
      "dependencies": [
        6
      ],
      "status": "pending",
      "subtasks": [
        {
          "id": 1,
          "title": "Create ScoreHUD UI",
          "description": "Build in-game score display with current and best score labels.",
          "details": "Create res://scripts/hud.gd extending CanvasLayer. Add Control with two Labels: @onready var _score_label: Label, @onready var _best_label: Label. Write func set_scores(score: int, best: int) -> void: _score_label.text = \"Score: %d\" % score, _best_label.text = \"Best: %d\" % best. Optionally create a .tscn (hud.tscn) with the layout, or build in code. Position labels at top of viewport (y=10, x=20 for score, x=320 for best).",
          "status": "pending",
          "dependencies": []
        },
        {
          "id": 2,
          "title": "Create TitleScreen UI",
          "description": "Build title screen with game name, high score, and start prompt.",
          "details": "Create res://scripts/title_screen.gd extending CanvasLayer. Add Control with Labels: title (\"SNAKE\"), best score (\"Best: %d\"), instructions (\"Press ENTER to Start\"). Write func set_best(best: int) -> void to update best score label. Position centered in viewport. Initially visible=true.",
          "status": "pending",
          "dependencies": []
        },
        {
          "id": 3,
          "title": "Create PauseOverlay UI",
          "description": "Build pause overlay with \"Paused\" message and resume prompt.",
          "details": "Create res://scripts/pause_overlay.gd extending CanvasLayer. Add Control with Label \"PAUSED\" and \"Press ESC or ENTER to Resume\" centered. Initially visible=false. No dynamic data, just static text. Toggled by Game._set_state.",
          "status": "pending",
          "dependencies": []
        },
        {
          "id": 4,
          "title": "Create GameOverScreen UI",
          "description": "Build game over screen showing final score, best score, and new-best indicator.",
          "details": "Create res://scripts/game_over_screen.gd extending CanvasLayer. Add Control with Labels: \"GAME OVER\", @onready var _score_label: Label (\"Score: %d\"), @onready var _best_label: Label (\"Best: %d\"), @onready var _new_best_label: Label (\"New Best!\" initially hidden), instructions (\"Press ENTER to Restart\"). Write func set_scores(score: int, best: int) -> void and func show_new_best(is_best: bool) -> void to update labels and toggle _new_best_label visibility. Initially visible=false.",
          "status": "pending",
          "dependencies": []
        },
        {
          "id": 5,
          "title": "Add all UI nodes to Main.tscn",
          "description": "Instantiate all HUD/screen CanvasLayers in the scene tree.",
          "details": "Open Main.tscn. Add four CanvasLayer children to Game root: ScoreHUD (attach hud.gd), TitleScreen (attach title_screen.gd), PauseOverlay (attach pause_overlay.gd), GameOverScreen (attach game_over_screen.gd). Set initial visibility: TitleScreen=true, others=false. In game.gd, get references via @onready vars. Update _set_state to toggle visibility. Update _start_new_game to call _score_hud.set_scores(0, _best_score). Update _on_tick ATE branch to call _score_hud.set_scores(_state.score, _best_score). Update _on_tick DIED branch to call _game_over_screen.set_scores and show_new_best. Run godot --headless --path snaketaskmaster --import.",
          "status": "pending",
          "dependencies": [
            1,
            2,
            3,
            4
          ]
        }
      ]
    },
    {
      "id": 9,
      "title": "Integration & Manual Testing",
      "description": "Wire all systems together and verify the complete vertical slice.",
      "details": "Run all unit tests (game_state_test, snake_logic_test, apple_logic_test, input_buffer_test) headlessly via gdUnit4. Fix any failures. Launch the game in Godot editor or standalone: verify title screen shows, Enter starts game, snake moves at 8 tiles/s, WASD/Arrows steer (no reversal), eating apple grows snake and increments score, hitting wall/self shows game over, restart works, high score persists across runs. This task has no code output, only verification and bug fixes.",
      "priority": "medium",
      "dependencies": [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8
      ],
      "status": "pending",
      "subtasks": [
        {
          "id": 1,
          "title": "Run all unit tests headlessly",
          "description": "Execute gdUnit4 test suite and verify all tests pass.",
          "details": "Run: godot --headless --path snaketaskmaster -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a test/. Verify exit code 0. Review output for any failures in game_state_test.gd, snake_logic_test.gd, apple_logic_test.gd, input_buffer_test.gd. If failures occur, fix the corresponding implementation or test, re-run until all pass.",
          "status": "pending",
          "dependencies": []
        },
        {
          "id": 2,
          "title": "Verify title screen and game start",
          "description": "Launch game and test title screen flow.",
          "details": "Run game in editor or standalone (godot --path snaketaskmaster). Verify: title screen displays \"SNAKE\", best score (0 on first run), and \"Press ENTER to Start\". Press Enter. Verify: transition to PLAYING, board renders with 3-segment snake heading right, one apple, score=0 displayed, timer ticking at 8 tiles/s. Fix any crashes, missing sprites, or FSM bugs.",
          "status": "pending",
          "dependencies": [
            1
          ]
        },
        {
          "id": 3,
          "title": "Verify movement and input handling",
          "description": "Test snake steering, buffer, and anti-reversal.",
          "details": "During PLAYING: press WASD/Arrow keys to steer. Verify: snake turns on next tick, no 180° reversal allowed (e.g., heading Right, pressing Left does nothing). Test input buffering: quickly press Up then Right within one tick; verify both turns apply on successive ticks. Test pause (Esc/P): timer stops, overlay shows, resume works. Fix input mapping or buffer bugs.",
          "status": "pending",
          "dependencies": [
            2
          ]
        },
        {
          "id": 4,
          "title": "Verify eating and growth",
          "description": "Test apple collision, score increment, and snake growth.",
          "details": "Steer snake into apple. Verify: flash_eat plays, score increments by 1, snake grows by one segment on next tick (tail doesn't pop), new apple spawns on a free tile. Eat multiple apples, verify growth accumulates. Fix AppleLogic or SnakeLogic.advance bugs if behavior incorrect.",
          "status": "pending",
          "dependencies": [
            3
          ]
        },
        {
          "id": 5,
          "title": "Verify collision and game over",
          "description": "Test wall and self-collision death triggers.",
          "details": "Steer snake into wall. Verify: flash_death plays, timer stops, game over screen shows with correct final score. Press Enter to restart, verify new game starts. Then: grow snake long enough to collide with own body. Verify: same death behavior. Test tail-vacate edge case: steer snake to follow its own tail end (legal move when not growing). Fix SnakeLogic.is_lethal or Game._on_tick DIED handling if incorrect.",
          "status": "pending",
          "dependencies": [
            4
          ]
        },
        {
          "id": 6,
          "title": "Verify score persistence",
          "description": "Test high score saving and loading across sessions.",
          "details": "Play game, score points (e.g., 5 apples), trigger game over. Verify: game over screen shows score=5, best=5, \"New Best!\" appears. Restart game within same session, score again but less (e.g., 3). Verify: game over shows score=3, best=5, no \"New Best!\". Close and relaunch game. Verify: title screen shows best=5. Play and beat it (e.g., 7). Verify: new best saved, persists on next relaunch. Fix ScoreStore or Game persistence logic if incorrect.",
          "status": "pending",
          "dependencies": [
            5
          ]
        },
        {
          "id": 7,
          "title": "Verify rendering and pixel alignment",
          "description": "Check visual correctness of board, snake, apple, and UI.",
          "details": "Inspect game visually: floor and wall tiles render correctly, snake head/body sprites distinct and aligned to pixel grid, apple renders on grid, no tearing or subpixel jitter (project.godot 2d/snap settings ensure this). Verify HUD labels readable and positioned correctly. Fix BoardView._draw or BOARD_ORIGIN/TILE_PX constants if layout broken.",
          "status": "pending",
          "dependencies": [
            6
          ]
        },
        {
          "id": 8,
          "title": "Edge case verification pass",
          "description": "Test known edge cases and boundary conditions.",
          "details": "Test: snake length 1 (only head, no body), verify movement and no self-collision. Test: board nearly full (fill with a long snake), verify apple spawns on remaining tiles. Test: board completely full (edit state or play until fill), verify apple spawn returns sentinel, game continues until unavoidable self-collision. Test: first tick after game start, snake moves immediately. Fix any edge case bugs in logic modules or Game orchestration.",
          "status": "pending",
          "dependencies": [
            7
          ]
        }
      ]
    }
  ],
  "metadata": null
}
```
