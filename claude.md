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

## Testing with gdUnit4

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