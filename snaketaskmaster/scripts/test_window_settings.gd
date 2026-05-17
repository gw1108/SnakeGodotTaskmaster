extends Node


func _ready() -> void:
	get_tree().create_timer(10.0).timeout.connect(func(): get_tree().quit(2))

	var vw: int = ProjectSettings.get_setting("display/window/size/viewport_width")
	var vh: int = ProjectSettings.get_setting("display/window/size/viewport_height")
	var mode: int = ProjectSettings.get_setting("display/window/size/mode")
	var stretch_mode: String = ProjectSettings.get_setting("display/window/stretch/mode")
	var stretch_aspect: String = ProjectSettings.get_setting("display/window/stretch/aspect")
	var snap_xforms: bool = ProjectSettings.get_setting("rendering/2d/snap/snap_2d_transforms_to_pixel")
	var snap_verts: bool = ProjectSettings.get_setting("rendering/2d/snap/snap_2d_vertices_to_pixel")

	assert(vw == 640, "viewport_width should be 640 (20 cells * 32px), got %d" % vw)
	assert(vh == 480, "viewport_height should be 480 (15 cells * 32px), got %d" % vh)
	assert(mode == 0, "window mode should be 0 (windowed), got %d" % mode)
	assert(stretch_mode == "viewport", "stretch mode should be 'viewport', got '%s'" % stretch_mode)
	assert(stretch_aspect == "keep", "stretch aspect should be 'keep', got '%s'" % stretch_aspect)
	assert(snap_xforms == true, "snap_2d_transforms_to_pixel should be true")
	assert(snap_verts == true, "snap_2d_vertices_to_pixel should be true")

	# Sanity check: viewport size matches the grid dimensions exactly
	assert(vw == GameConstants.GRID_WIDTH * GameConstants.CELL_SIZE,
		"viewport_width must equal GRID_WIDTH * CELL_SIZE")
	assert(vh == GameConstants.GRID_HEIGHT * GameConstants.CELL_SIZE,
		"viewport_height must equal GRID_HEIGHT * CELL_SIZE")

	print("OK: all window settings tests passed")
	get_tree().quit(0)
