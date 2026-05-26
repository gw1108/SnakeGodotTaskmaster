# Claude.md

The role of this file is to describe common mistakes and confusion points that agents might encounter as they work in this project. If you ever encounter something in the project that surprises you, please alert the developer working with you and indicate that this is the case in the AgentMD file to help prevent future agents from having the same issue.

---

## Operating Principles (Non-Negotiable)

- If something is described or asked for do not ask for confirmation.

---

## Project Structure

Godot is on PATH.
The Godot project lives in `snaketaskmaster/`, NOT the repo root. Run `godot` commands with `--path snaketaskmaster`

Do NOT scan files under any folder named ARCHIVE or addons unless specified.

### Re-import after adding files

Whenever new files are added or created in the Godot project (scripts, scenes, resources, assets), run the headless import so Godot picks them up and generates `.import`/`.uid` metadata:

```powershell
godot --headless --path snaketaskmaster --import
```

The gdUni4, editor, and `preload(...)` calls will not resolve new files until this completes.

### Type checking

GDScript type errors and syntax errors are caught at compile time by the Godot engine.
After writing or editing code, check for them by running Godot headless:

- **Whole project** (preferred — full project context). Run from `snaketaskmaster/`:
  ```powershell
  godot --headless --path snaketaskmaster --import
  ```
Recompiles every script and prints any parse/type errors; returns non-zero on error. (Same import command used after adding files.)

- **Single file** (faster). Run from `snaketaskmaster/`:
  ```powershell
  godot --headless --path snaketaskmaster --check-only --script res://path/to/file.gd
  ```
Checks a single script for parse/type errors. For project-wide checks, use the `--import` command above.

---

## Test Guidelines
Read TESTING.md for more details if you plan on writing tests.

### Testing with gdUnit4

The project uses **gdUnit4 v6.0.0** (installed at `snaketaskmaster/addons/gdUnit4/`)

### File layout
- Tests live in `snaketaskmaster/test/`
- One test file per unit under test, mirroring its name: `player.gd` → `test/player_test.gd`
- Filename must end in `_test.gd` (gdUnit4 discovery convention). No `.tscn` companion needed

### Running tests
- **Headless** (from `snaketaskmaster/`):
  ```powershell
  godot --headless --path snaketaskmaster -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a test/<file>_test.gd
  ```
  Exit code 0 on pass. `-a <path>` can be a file or a directory.

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