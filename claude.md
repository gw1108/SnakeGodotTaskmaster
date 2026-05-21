# Claude.md

The role of this file is to describe common mistakes and confusion points that agents might encounter as they work in this project. If you ever encounter something in the project that surprises you, please alert the developer working with you and indicate that this is the case in the AgentMD file to help prevent future agents from having the same issue.

---

## Operating Principles (Non-Negotiable)

- If something is described or asked for do not ask for confirmation.

---

## Project Structure

Godot is on PATH.
The Godot project lives in `snaketaskmaster/`, NOT the repo root. Run `godot` commands with `--path snaketaskmaster` (or `cd snaketaskmaster` first).

Do NOT scan files in the /thoughts/ folder unless specified.
Do NOT scan files under any folder named ARCHIVE unless specified.

---

## Test Guidelines

### Keep Tests Synchronous Where Possible

- **Only use `await` when you genuinely need to wait** — for a signal, a frame (`await get_tree().process_frame`), a timer, or an async API. Don't sprinkle it on tests that don't actually need it.
- Prefer `preload(...)` at the top of the test file over `load(...)` inside test methods — it's faster and surfaces missing-resource errors at parse time.
- If a test must wait for a signal, use `await_signal_on(emitter, "signal_name", [args], timeout_ms)` from `GdUnitTestSuite` so it fails fast instead of hanging.
- Example:

  ```gdscript
  const Player := preload("res://scripts/player.gd")

  # ✅ CORRECT - Synchronous: no signals, no frames involved
  func test_player_starts_with_full_health() -> void:
      var player := auto_free(Player.new())
      assert_int(player.health).is_equal(player.max_health)

  # ✅ CORRECT - Async is justified: actually waiting on a signal
  func test_player_emits_died_when_health_hits_zero() -> void:
      var player := auto_free(Player.new())
      player.take_damage(player.max_health)
      await await_signal_on(player, "died", [], 100)

  # ❌ INCORRECT - Unnecessary async wrapper around sync logic
  func test_damage_reduces_health() -> void:
      var player := auto_free(Player.new())
      await get_tree().process_frame   # nothing here needs a frame
      player.take_damage(10)
      assert_int(player.health).is_equal(player.max_health - 10)
  ```

### When to Write Tests

**ALWAYS write tests for:**

- **Bug fixes**: Add a regression test that would have caught the bug
- **Game logic**: State machines, stat/formula calculations, inventory/resource math, save-data serialization
- **Edge cases**: Boundary conditions (min/max values, empty collections), error paths, null-node guards
- **Public APIs**: Methods and signals other scripts or scenes depend on
- **Integration points**: Resource loading, file I/O, autoloads

**SKIP tests for:**

- Trivial property access or one-line setters that just assign a field
- Pure pass-through wrappers with no logic
- Exported config-only resources (`@export` vars with no behavior)
- Code that just forwards to an already-tested autoload or helper

**Examples:**

```gdscript
# ✅ WRITE A TEST - Bug fix with regression prevention
func test_take_damage_clamps_health_at_zero() -> void:
    var entity := auto_free(Entity.new())
    entity.max_health = 100
    entity.health = 10
    entity.take_damage(50)
    assert_int(entity.health).is_equal(0)

# ✅ WRITE A TEST - Game logic with edge cases
func test_state_machine_rejects_invalid_transitions() -> void:
    var fsm := auto_free(StateMachine.new())
    fsm.set_state("idle")
    assert_bool(fsm.try_transition("attack")).is_true()
    assert_bool(fsm.try_transition("nonexistent_state")).is_false()
    assert_str(fsm.current_state).is_equal("attack")

# ❌ SKIP TEST - Trivial property access
class_name Item
var display_name: String       # no test needed

# ❌ SKIP TEST - Pure delegation to an already-tested autoload
func get_setting(key: String) -> Variant:
    return Settings.get_value(key)    # Settings is covered elsewhere
```

### Testing with gdUnit4

The project uses **gdUnit4 v6.0.0** (installed via AssetLib at `snaketaskmaster/addons/gdUnit4/`). Use it for all new tests.

### File layout
- Tests live in `snaketaskmaster/test/`. Do NOT put tests in `scripts/`.
- One test file per unit under test, mirroring its name: `player.gd` → `test/player_test.gd`.
- Filename must end in `_test.gd` (gdUnit4 discovery convention). No `.tscn` companion needed.

### Test file skeleton

```gdscript
extends GdUnitTestSuite

# Optional lifecycle hooks — omit if not needed:
func before() -> void: pass         # once per suite
func after() -> void: pass          # once per suite
func before_test() -> void: pass    # before each test_*
func after_test() -> void: pass     # after each test_*

func test_something() -> void:      # methods MUST start with test_
    assert_that(actual).is_equal(expected)
```

### Assertions
- Generic: `assert_that(x).is_equal(y)` works for any type.
- Typed (better error messages): `assert_int`, `assert_str`, `assert_bool`, `assert_float`, `assert_array`, `assert_dict`, `assert_object`, `assert_func`, `assert_file`, `assert_godot_error`.
- Chain: `.is_equal(v)`, `.is_not_equal(v)`, `.is_true()`, `.is_false()`, `.is_null()`, `.is_not_null()`, `.contains(v)`, `.has_size(n)`, etc.

### Node / object tests
- Wrap created objects in `auto_free(obj)` so gdUnit4 frees them after the test.
- `add_child(node)` is overridden by `GdUnitTestSuite` to track orphans — use it as normal; orphan counts surface in the summary.

### Running tests
- **Editor**: FileSystem dock → right-click the test file → **Run Test(s)**. Or use the gdUnit Inspector bottom dock.
- **Headless** (from `snaketaskmaster/`):
  ```powershell
  godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a test/<file>_test.gd
  ```
  Exit code 0 on pass. `-a <path>` can be a file or a directory.

### Gotchas
- **gdUnit4 refuses headless by default** — always pass `--ignoreHeadlessMode` for CLI runs. UI / InputEvent tests genuinely won't work headless; run them from the editor.
- **`runtest.cmd` is at `addons/gdUnit4/runtest.cmd`** (not the project root) and uses `-d` (debug = opens a window). For CI/headless use the `GdUnitCmdTool.gd` invocation above.
- **Godot 4.6.2 compat patch in `addons/gdUnit4/src/core/GdUnitFileAccess.gd:199`** — changes `file.get_as_text(true)` → `file.get_as_text()`. Without it, the entire addon fails to compile. Re-installing or updating gdUnit4 via AssetLib will overwrite this patch — re-apply (or check whether upstream 6.0.1+ has fixed it).
- **Test reports** are written to `snaketaskmaster/reports/` and are gitignored. Don't commit them.

---

## Gameplay Tuning (final values)

These values were settled during task 19 (gameplay parameter tuning). Treat them as the project's defaults; if you change one, update this section and check the constraints below.

| Parameter | Value | Where | Rationale |
|---|---|---|---|
| `grid_width` | 20 | `arena.gd` `@export` (default on `Arena.tscn`) | 18 playable columns after walls — wide enough for sustained horizontal runs, narrow enough that the player must turn often |
| `grid_height` | 15 | `arena.gd` `@export` | 13 playable rows — keeps the play field landscape (matches 4:3 viewport) |
| `cell_size` | 32 | `arena.gd` `@export` | Sprite art is authored at 32px; smaller cells look mushy at this viewport |
| `viewport_width` | 640 | `project.godot` `[display]` | Must equal `grid_width * cell_size` (20 × 32 = 640) — otherwise tiles are clipped or the play area is letterboxed |
| `viewport_height` | 480 | `project.godot` `[display]` | Must equal `grid_height * cell_size` (15 × 32 = 480) |
| `TickTimer.wait_time` | 0.15 s | `Gameplay.tscn` | ~6.7 ticks/sec — fast enough to feel brisk, slow enough that a reaction-time turn lands on the next cell rather than overshooting |
| `DeathTimer.wait_time` | 0.5 s | `Gameplay.tscn` | Long enough to register the death audio + visual before transitioning to game over |
| `Snake.starting_head` | (5, 7) | `snake.gd` `@export` | Left-of-center horizontally, vertically centered. Snake starts facing right with body at (5,7),(4,7),(3,7), giving ~13 cells of runway before the right wall — enough to read the screen and pick a direction. Tests hardcode this position; bump them together if you move it |
| `Snake.starting_length` | 3 | `snake.gd` `@export` | Classic Snake starting length; anything longer crowds the small grid |

**Constraint to preserve:** `viewport_width == grid_width * cell_size` and `viewport_height == grid_height * cell_size`. If you tune the grid, also resize the viewport in `project.godot` or you'll get visible clipping/letterboxing.

---

## Web (HTML5) Export

The `Web` preset is defined in `snaketaskmaster/export_presets.cfg` and writes to `snaketaskmaster/build/web/index.html`. `build/` is gitignored.

- **Export templates are required and not committed.** Install via Editor → Manage Export Templates → Download and Install (Godot 4.6.2 templates). Without templates, the CLI export creates a partial `.tmp` file and exits with code 255.
- **CLI export** (after templates are installed):
  ```powershell
  godot --headless --path snaketaskmaster --export-release "Web" "build/web/index.html"
  ```
- **Local browser test:** HTML5 builds need an HTTP server (file:// won't work due to CORS). From `snaketaskmaster/build/web/`:
  ```powershell
  python -m http.server 8000
  # then open http://localhost:8000/index.html
  ```

---

## Windows Desktop Export

The `Windows Desktop` preset is defined in `snaketaskmaster/export_presets.cfg` and writes to `snaketaskmaster/build/windows/snake.exe`. PCK is embedded (`binary_format/embed_pck=true`), so the export produces a single self-contained `.exe`. `build/` is gitignored and `*.exe` is independently gitignored.

- **Export templates are required** (same caveat as the Web preset). Install via Editor → Manage Export Templates.
- **The output directory must exist before exporting.** The CLI export errors with "The given export path doesn't exist" if `build/windows/` is missing. Create it first:
  ```powershell
  New-Item -ItemType Directory -Force snaketaskmaster\build\windows
  godot --headless --path snaketaskmaster --export-release "Windows Desktop" "build/windows/snake.exe"
  ```
- **A post-export editor-process crash (SIGSEGV) is harmless** in this configuration — the `.exe` is fully written before the crash. Verify `snake.exe` exists and is ~100 MB before assuming the export failed. The bash wrapper reports `EXIT: 0` despite the backtrace.
- **Manual verification:** double-click `snake.exe` and confirm the title screen appears, controls respond, audio plays, and the full gameplay loop runs to game-over. No Godot install is required to run the embedded build.

---

## Workflow Orchestration

### 1. Subagent Strategy (Parallelize Intelligently)
- Use subagents to keep the main context clean and to parallelize:
  - repo exploration, pattern discovery, test failure triage, dependency research, risk review.
- Give each subagent **one focused objective** and a concrete deliverable:
  - "Find where X is implemented and list files + key functions" beats "look around."

### 2. Incremental Delivery (Reduce Risk)
- Prefer **thin vertical slices** over big-bang changes.

### 3. Self-Improvement Loop
- After any user correction or a discovered mistake, add a new entry to `tasks/lessons.md`.
- Keep each entry minimal: a short **category header** (e.g. `### Research scoping`) plus a **one-line prevention rule**. Nothing else.
- The category lets future agents skim and skip entries that look unrelated without reading the body. If a rule needs more context to be actionable, the category itself is too broad.
- Before adding a new entry, check if an existing category already covers it; extend or refine that line instead of duplicating.

---

### Code Intelligence

Prefer LSP over Grep/Glob/Read for code navigation:
- `goToDefinition` / `goToImplementation` to jump to source
- `findReferences` to see all usages across the codebase
- `workspaceSymbol` to find where something is defined
- `documentSymbol` to list all symbols in a file
- `hover` for type info without reading the file
- `incomingCalls` / `outgoingCalls` for call hierarchy

Before renaming or changing a function signature, use
`findReferences` to find all call sites first.

Use Grep/Glob only for text/pattern searches (comments,
strings, config values) where LSP doesn't help.

After writing or editing code, check LSP diagnostics before
moving on. Fix any type errors or missing imports immediately.