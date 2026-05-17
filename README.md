# Snake (Godot 4) — Taskmaster Project

A small 2D grid-based snake game built in Godot 4.6 with PixelLab-generated sprites. The project was driven through Taskmaster, with each gameplay slice implemented and tested headlessly before moving on.

## Game Overview

Steer a snake around a 20×15 cell playfield, eating apples to grow longer and rack up score. The game ends when the snake hits a wall or runs into its own body. The high score persists across runs within the same session.

- Playfield: 20 wide × 15 tall grid of 32px cells (640×480 viewport)
- Snake starts at length 3, moving right
- Each apple eaten: +1 score, +1 segment
- Game-over screen shows your final score, why you died, and flags a new high score when applicable

## Controls

| Action | Keys |
| --- | --- |
| Move up | `Up Arrow` / `W` |
| Move down | `Down Arrow` / `S` |
| Move left | `Left Arrow` / `A` |
| Move right | `Right Arrow` / `D` |
| Start game (title screen) | Any key |
| Restart (game-over screen) | Any key |

180° reversals are blocked so you can't fold the snake onto itself in a single tick. Inputs are buffered between ticks, so quick perpendicular turns are picked up at the next movement step.

## How to Run

1. Install [Godot 4.6](https://godotengine.org/).
2. Clone this repo.
3. Open `snaketaskmaster/project.godot` in the Godot editor.
4. Press `F5` (or click Play) to launch. The game boots into the title screen — press any key to start.

To run from the command line (Godot on PATH):

```
godot --path snaketaskmaster
```

### Headless tests

Each gameplay system has a corresponding test scene under `snaketaskmaster/scenes/test_*.tscn`. Run any of them headlessly, for example:

```
godot --headless --path snaketaskmaster res://scenes/test_integration.tscn
```

A successful run prints `OK: ...` and exits with code 0.

## How to Build (Windows desktop)

1. Open the project in Godot 4.6.
2. `Project → Export…`
3. Add a `Windows Desktop` preset; install the export templates when prompted (`Editor → Manage Export Templates…`).
4. Set an export path (e.g. `build/snaketaskmaster.exe`) and click `Export Project`.
5. The resulting `.exe` plus its `.pck` can be distributed together.

The same flow works for Linux/macOS by adding the matching preset and templates.

## Project Layout

```
snaketaskmaster/
  project.godot         # Godot project (entry: scenes/title_screen.tscn)
  assets/
    sprites/            # PixelLab-generated: player_head, player_body, food, floor_tile, wall_tile
    audio/              # Placeholder eat_food.wav and death.wav (procedurally generated)
  scenes/               # title_screen, game, game_over_screen, playfield, plus test_* scenes
  scripts/              # gameplay scripts + matching test_* scripts
```

Autoloads: `GameConstants` (grid dimensions, tick interval, coord helpers), `InputManager` (buffered direction input with reversal blocking), `GameState` (score, high score, collision type).

## Credits

- **Sprites:** generated via the [PixelLab](https://www.pixellab.ai/) MCP server (`create_object` for the snake head/body and food; `create_tiles_pro` for the floor and wall border tiles).
- **Audio:** placeholder eat-food and death SFX synthesized as raw 16-bit PCM WAV via PowerShell — no third-party samples used.
- **Engine:** [Godot 4.6](https://godotengine.org/).
- **Task orchestration:** [Taskmaster AI](https://www.task-master.dev/).

## Contact

George Wang — georgetw1108@gmail.com
