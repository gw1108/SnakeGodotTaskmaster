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