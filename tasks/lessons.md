### Test typing
gdUnit4 treats warnings as errors — never use `:=` with `auto_free(...)` (infers Variant); type explicitly, e.g. `var x: Snake = auto_free(Snake.new())`.

### Input testing
Test input via polling (`Input.action_press` + `_process(0)`), not `_input`/InputEvents (dead headless); release actions in `after_test()`. Note `action_press` does NOT set `is_anything_pressed()`.
