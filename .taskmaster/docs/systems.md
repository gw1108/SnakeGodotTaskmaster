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
