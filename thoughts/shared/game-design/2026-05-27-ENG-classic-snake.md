# Game Design Document: Classic Snake

## Concept
**Steer a continuously-moving snake around a walled playfield, eat apples to grow, and survive as long as you can without crashing into the walls or your own ever-lengthening tail.**

The player controls the head of a snake that never stops moving. Every apple eaten adds a segment, making the tail a larger and larger obstacle to your own future path. There is no win screen — the game is a pure endless high-score chase where the tension comes entirely from managing a body that keeps getting harder to avoid. It's compelling because it pairs split-second reactions with constant forward planning, and it's instantly understood by anyone.

## Source Document
`.firecrawl/snake-gameplay-extracted.md` (a genre-level description of Snake; the specific design below was clarified with the user).

## Genre & References
- **Genre:** Single-player arcade / action.
- **References:** Classic Nokia *Snake* (absolute 4-direction, walled board, endless score chase) as the primary touchstone, with a modern colorful pixel-art coat of paint rather than the monochrome LCD look.

## Platform & Audience
- **Platform:** Desktop (Godot export). PC primary.
- **Input:** Keyboard — arrow keys and/or WASD.
- **Audience:** Players who enjoy quick, pick-up-and-play arcade score chasers; broad/casual appeal.

## Core Gameplay Loop
1. The snake moves forward automatically, one grid cell per tick, at a constant speed.
2. The player steers with absolute direction inputs to aim the head toward the apple.
3. Eating the apple grows the snake by one segment, awards points, and spawns a new apple.
4. The longer tail makes the next apple harder to reach safely.
5. Repeat until the head collides with a wall or the body → game over → see score vs. best → restart.

The satisfaction is the rising-tension feedback loop: each reward (an apple) directly increases the difficulty (a longer tail), forcing increasingly careful path planning while the snake never slows or stops.

## Player Verbs & Controls
- **Steer up / down / left / right** — Arrow keys or WASD set the snake's absolute heading.
- **Reverse guard:** An input that would send the head straight back along its own neck (180° reversal) is ignored; the snake continues in its current direction.
- **Restart** — From the game-over screen, a key press (e.g. Enter/Space) starts a new run.
- The snake cannot stop, pause its motion, or change speed via input.

## Mechanics & Rules

### Movement
- Grid-based. The snake advances exactly one cell per tick.
- **Constant speed:** one step every ~125 ms (~8 cells/sec) for the entire run; speed never changes.
- The head moves to the next cell in the current heading; each body segment follows the cell its predecessor occupied. When not eating, the tail vacates its last cell (net length unchanged).

### Eating & Growth
- Exactly **one apple** exists on the field at any time.
- Eating an apple (head enters the apple's cell):
  - Snake grows by **+1 segment** (the tail does not vacate that tick).
  - Score increases by **+10 points**.
  - A new apple immediately spawns on a uniformly random **free** cell (never under the snake's body).

### Collision & Failure
- **Wall collision:** head moving into the outer boundary ends the run.
- **Self collision:** head entering a cell occupied by any body segment ends the run.
- There is one life; collision is immediate game over.

### Scoring & High Score
- Score = points accumulated this run (10 per apple).
- A single **best score** is persisted locally between sessions and displayed on the HUD and game-over screen.

## Game Objects & Entities

### Snake
- An ordered chain of segments: one head + body segments.
- **Starting length:** 3 segments.
- Moves as a unit each tick; grows by appending a segment when eating.
- States: alive (moving) / dead (collision triggered).

### Apple (Food)
- A single collectible occupying one cell.
- Spawns on a random free cell; consumed on contact with the head; respawns elsewhere immediately.
- No timer, no movement, no variants (classic minimalist scope).

### Playfield / Walls
- A fixed `20 × 20` grid of cells bounded by solid, lethal outer walls.
- No interior walls or maze geometry.

## Win / Lose Conditions
- **Lose:** head collides with an outer wall or with the snake's own body. Immediate game over.
- **Win:** none — the game is endless. The implicit goal is to beat the persisted best score. (Filling the entire board is not a designed win/perfect-run state in this iteration; it's an effectively unreachable theoretical ceiling.)

## Progression & Difficulty
- No levels, stages, or speed changes.
- Difficulty escalates organically and solely through snake length: the longer the tail, the less free space and the more constrained safe pathing becomes.
- Replayability comes from chasing a higher score.

## World / Level Structure
- A single, fixed, authored screen: one `20 × 20` walled arena.
- No procedural generation beyond random apple placement.
- Boundaries are solid and lethal (no wrap-around).

## Art & Visual Direction
- **Style:** Colorful modern pixel art (not retro monochrome).
- **Snake:** shaded/colored segments (e.g. a distinct head sprite plus body segments); readable direction.
- **Apple:** a juicy, clearly readable food sprite.
- **Background:** a decorated/colored grid arena with a visible border denoting the lethal walls.
- **Resolution:** `16px` cells → `320 × 320` px native playfield (plus HUD space as needed), integer-scaled up to the window (e.g. 640×640 or 960×960) to keep pixels crisp.

## Audio Direction
- **Music:** a looping chiptune background track during play.
- **SFX:** eat (apple consumed), and death/collision; optionally a subtle turn cue.
- Audio reinforces the retro-arcade feel and gives satisfying feedback on the key moment (eating).

## UI / UX
- **HUD (in-game):** current score and best score visible.
- **Game-over screen:** final score, best score, and a clear "press to restart" prompt.
- **Feedback / juice:** clear visual + audio confirmation on eating; readable death moment.
- Minimal menus consistent with a pick-up-and-play arcade game (a simple start/title state is acceptable).

## Scope

### MVP (first playable)
- 20×20 walled grid, constant-speed grid movement.
- Absolute 4-direction steering with reverse guard.
- One apple at a time; eat → +1 segment, +10 points, respawn on free cell.
- Wall and self collision → game over.
- Score + persisted best score; game-over + restart.
- Colorful pixel-art snake/apple/arena; chiptune music + eat/death SFX.

### Later / Stretch
- Power-ups / special food (bonus, multipliers, temporary effects).
- Enemy/AI snakes.
- Maze layouts / authored level progression.
- Speed escalation modes.
- Wrap-around / selectable rule variants.
- Turn-relative control scheme as an option.

### Non-Goals
- No multiplayer (the original two-player genre format is explicitly out).
- No speed changes during a run.
- No interior walls/mazes.
- No win/victory state in this iteration.
- No multiple simultaneous food items or food variants.

## Technical Constraints
- **Engine:** Godot. Project lives in `snaketaskmaster/`.
- **Rendering:** 2D pixel art, integer-scaled.
- Grid-tick logic decoupled from frame rate so the constant ~8 cells/sec cadence is stable.

## Open Questions
- None blocking. Minor items to settle during build: exact window scale factor (640×640 vs 960×960), whether a dedicated title/start screen ships in MVP or play begins immediately, and whether a subtle turn SFX is included alongside eat/death.
