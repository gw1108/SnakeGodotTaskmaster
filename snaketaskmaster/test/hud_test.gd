extends GdUnitTestSuite

const HUD_SCRIPT_PATH := "res://scripts/hud.gd"
const HUD_SCENE_PATH := "res://scenes/hud.tscn"
const GAME_SCENE_PATH := "res://scenes/game.tscn"


func test_hud_script_file_exists() -> void:
	assert_file(HUD_SCRIPT_PATH).exists()


func test_hud_scene_file_exists() -> void:
	assert_file(HUD_SCENE_PATH).exists()


func test_hud_scene_instantiates_as_canvas_layer() -> void:
	var packed := load(HUD_SCENE_PATH) as PackedScene
	assert_object(packed).is_not_null()
	var hud: CanvasLayer = auto_free(packed.instantiate())
	add_child(hud)
	assert_object(hud).is_instanceof(CanvasLayer)


func test_hud_has_score_label_child() -> void:
	var packed := load(HUD_SCENE_PATH) as PackedScene
	var hud: CanvasLayer = auto_free(packed.instantiate())
	add_child(hud)
	var label := hud.get_node_or_null("ScoreLabel")
	assert_object(label).is_not_null()
	assert_object(label).is_instanceof(Label)


func test_hud_initial_score_label_text() -> void:
	var packed := load(HUD_SCENE_PATH) as PackedScene
	var hud: CanvasLayer = auto_free(packed.instantiate())
	add_child(hud)
	var label: Label = hud.get_node("ScoreLabel")
	assert_str(label.text).is_equal("Score: 0")


func test_update_score_sets_label_text_zero() -> void:
	var hud: CanvasLayer = auto_free((load(HUD_SCENE_PATH) as PackedScene).instantiate())
	add_child(hud)
	hud.update_score(0)
	var label: Label = hud.get_node("ScoreLabel")
	assert_str(label.text).is_equal("Score: 0")


func test_update_score_sets_label_text_positive() -> void:
	var hud: CanvasLayer = auto_free((load(HUD_SCENE_PATH) as PackedScene).instantiate())
	add_child(hud)
	hud.update_score(5)
	var label: Label = hud.get_node("ScoreLabel")
	assert_str(label.text).is_equal("Score: 5")


func test_update_score_uses_latest_value() -> void:
	var hud: CanvasLayer = auto_free((load(HUD_SCENE_PATH) as PackedScene).instantiate())
	add_child(hud)
	hud.update_score(1)
	hud.update_score(2)
	hud.update_score(42)
	var label: Label = hud.get_node("ScoreLabel")
	assert_str(label.text).is_equal("Score: 42")


func test_update_score_handles_large_value() -> void:
	var hud: CanvasLayer = auto_free((load(HUD_SCENE_PATH) as PackedScene).instantiate())
	add_child(hud)
	hud.update_score(9999)
	var label: Label = hud.get_node("ScoreLabel")
	assert_str(label.text).is_equal("Score: 9999")


func test_game_scene_uses_hud_instance() -> void:
	var packed := load(GAME_SCENE_PATH) as PackedScene
	var game: Node2D = auto_free(packed.instantiate())
	add_child(game)
	var hud := game.get_node_or_null("HUD")
	assert_object(hud).is_not_null()
	assert_object(hud).is_instanceof(CanvasLayer)
	var label := hud.get_node_or_null("ScoreLabel")
	assert_object(label).is_not_null()
	assert_object(label).is_instanceof(Label)


func test_game_scene_hud_update_score_works() -> void:
	var packed := load(GAME_SCENE_PATH) as PackedScene
	var game: Node2D = auto_free(packed.instantiate())
	add_child(game)
	var hud: CanvasLayer = game.get_node("HUD")
	hud.update_score(7)
	var label: Label = hud.get_node("ScoreLabel")
	assert_str(label.text).is_equal("Score: 7")


func test_hud_has_game_over_panel_hidden_by_default() -> void:
	var hud: CanvasLayer = auto_free((load(HUD_SCENE_PATH) as PackedScene).instantiate())
	add_child(hud)
	var panel := hud.get_node_or_null("GameOverPanel")
	assert_object(panel).is_not_null()
	assert_object(panel).is_instanceof(Panel)
	assert_bool((panel as Panel).visible).is_false()


func test_game_over_panel_has_required_labels() -> void:
	var hud: CanvasLayer = auto_free((load(HUD_SCENE_PATH) as PackedScene).instantiate())
	add_child(hud)
	var vbox := hud.get_node_or_null("GameOverPanel/VBoxContainer")
	assert_object(vbox).is_not_null()
	for child_name in ["GameOverLabel", "FinalScoreLabel", "RestartPromptLabel"]:
		var label := vbox.get_node_or_null(child_name)
		assert_object(label).is_not_null()
		assert_object(label).is_instanceof(Label)
	assert_str((vbox.get_node("GameOverLabel") as Label).text).is_equal("Game Over")
	assert_str((vbox.get_node("RestartPromptLabel") as Label).text).is_equal("Press any key to restart")


func test_show_game_over_makes_panel_visible_and_sets_final_score() -> void:
	var hud: CanvasLayer = auto_free((load(HUD_SCENE_PATH) as PackedScene).instantiate())
	add_child(hud)
	hud.show_game_over(7)
	var panel: Panel = hud.get_node("GameOverPanel")
	var label: Label = hud.get_node("GameOverPanel/VBoxContainer/FinalScoreLabel")
	assert_bool(panel.visible).is_true()
	assert_str(label.text).is_equal("Final Score: 7")


func test_show_game_over_uses_latest_value() -> void:
	var hud: CanvasLayer = auto_free((load(HUD_SCENE_PATH) as PackedScene).instantiate())
	add_child(hud)
	hud.show_game_over(3)
	hud.show_game_over(42)
	var label: Label = hud.get_node("GameOverPanel/VBoxContainer/FinalScoreLabel")
	assert_str(label.text).is_equal("Final Score: 42")


func test_hide_game_over_hides_panel() -> void:
	var hud: CanvasLayer = auto_free((load(HUD_SCENE_PATH) as PackedScene).instantiate())
	add_child(hud)
	hud.show_game_over(5)
	assert_bool((hud.get_node("GameOverPanel") as Panel).visible).is_true()
	hud.hide_game_over()
	assert_bool((hud.get_node("GameOverPanel") as Panel).visible).is_false()
