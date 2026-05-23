extends GdUnitTestSuite

const HUD_SCENE_PATH := "res://scenes/HUD.tscn"


func _make_hud() -> HUD:
	var hud: HUD = auto_free(load(HUD_SCENE_PATH).instantiate())
	add_child(hud)
	return hud


func test_initial_score_is_zero() -> void:
	var hud: HUD = _make_hud()
	assert_int(hud.score).is_equal(0)


func test_initial_label_shows_zero() -> void:
	var hud: HUD = _make_hud()
	var label: Label = hud.get_node("ScoreLabel")
	assert_str(label.text).is_equal("Score: 0")


func test_update_score_sets_score_and_label() -> void:
	var hud: HUD = _make_hud()
	hud.update_score(5)
	var label: Label = hud.get_node("ScoreLabel")
	assert_int(hud.score).is_equal(5)
	assert_str(label.text).is_equal("Score: 5")


func test_update_score_overwrites_previous_value() -> void:
	var hud: HUD = _make_hud()
	hud.update_score(3)
	hud.update_score(42)
	var label: Label = hud.get_node("ScoreLabel")
	assert_int(hud.score).is_equal(42)
	assert_str(label.text).is_equal("Score: 42")


func test_reset_returns_score_to_zero() -> void:
	var hud: HUD = _make_hud()
	hud.update_score(17)
	hud.reset()
	var label: Label = hud.get_node("ScoreLabel")
	assert_int(hud.score).is_equal(0)
	assert_str(label.text).is_equal("Score: 0")


func test_hud_root_is_canvas_layer() -> void:
	var hud: HUD = _make_hud()
	assert_bool(hud is CanvasLayer).is_true()


@warning_ignore("unused_parameter")
func test_update_score_formats_label_for_value(value: int, expected_text: String, test_parameters := [
	[0, "Score: 0"],
	[1, "Score: 1"],
	[10, "Score: 10"],
	[999, "Score: 999"],
]) -> void:
	var hud: HUD = _make_hud()
	hud.update_score(value)
	var label: Label = hud.get_node("ScoreLabel")
	assert_int(hud.score).is_equal(value)
	assert_str(label.text).is_equal(expected_text)
