

### Keep Tests Synchronous Where Possible

- **Only use `await` when you genuinely need to wait** — for a signal, a frame (`await get_tree().process_frame`), a timer, or an async API. Don't sprinkle it on tests that don't actually need it.
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

- **Edge cases**: Boundary conditions (min/max values, empty collections), error paths, null-node guards

**SKIP tests for:**

- Trivial property access or one-line setters that just assign a field
- Pure pass-through wrappers with no logic
- Initialization or constructing objects
- Validating visual rendering. You may instead write a unit test that validates the sprites are assigned one time and then delete the unit test.

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

# ❌ RUN TEST THEN DELETE - Validates visual sprite is set. Should be deleted after success.
func test_border_cells_use_wall_texture() -> void:
    var renderer := _make_renderer()
    # All four corners plus a mid-edge cell are borders.
    for cell in [
        Vector2i(0, 0),
        Vector2i(Grid.GRID_WIDTH - 1, 0),
        Vector2i(0, Grid.GRID_HEIGHT - 1),
        Vector2i(Grid.GRID_WIDTH - 1, Grid.GRID_HEIGHT - 1),
        Vector2i(Grid.GRID_WIDTH / 2, 0),
    ]:
        var sprite := _sprite_at(renderer, cell)
        assert_object(sprite).is_not_null()
        assert_object(sprite.texture).is_same(ArenaRenderer.WALL_TEXTURE)
```

### Golden Path Test
There should be a golden path test. This test is like an integration test and represents what the player is expected to typically do. It is meant to play the game so claude can verify interactions in the core game loop.

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

### Gotchas
- Prefer `preload(...)` at the top of the test file over `load(...)` inside test methods — it's faster and surfaces missing-resource errors at parse time.
- Test input via polling (`Input.action_press` + `_process(0)`), not `_input`/InputEvents (dead headless); release actions in `after_test()`. Note `action_press` does NOT set `is_anything_pressed()`.
- Use `auto_free(obj)` so gdUnit4 frees them after the test. Never use `:=` with `auto_free(...)` (infers Variant); type explicitly, e.g. `var x: Snake = auto_free(Snake.new())`.
- `add_child(node)` is overridden by `GdUnitTestSuite` to track orphans — use it as normal; orphan counts surface in the summary.
- **gdUnit4 refuses headless by default** — always pass `--ignoreHeadlessMode` for CLI runs. UI / InputEvent tests genuinely won't work headless; run them from the editor.
- **`runtest.cmd` is at `addons/gdUnit4/runtest.cmd`** (not the project root) and uses `-d` (debug = opens a window). For CI/headless use the `GdUnitCmdTool.gd` invocation above.

### Input testing
Test input via polling (`Input.action_press` + `_process(0)`), not `_input`/InputEvents (dead headless); release actions in `after_test()`. Note `action_press` does NOT set `is_anything_pressed()`.