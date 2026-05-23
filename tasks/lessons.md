### GDScript validation
After editing any `.gd` file, run `godot --headless --path snaketaskmaster --quit` and check stderr for parse errors before marking the task done.

### Global class cache
After adding a new `class_name X`, run `godot --headless --path snaketaskmaster --import` before headless gdUnit4 runs — otherwise tests typing `var v: X` fail with "Could not find type 'X' in the current scope".