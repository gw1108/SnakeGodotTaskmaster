extends Node

func _ready() -> void:
	get_tree().create_timer(10.0).timeout.connect(func(): get_tree().quit(2))

	var playfield := $Playfield
	var floor_layer: TileMapLayer = playfield.get_node("FloorLayer")
	var wall_layer: TileMapLayer = playfield.get_node("WallLayer")

	# Allow playfield._ready to populate cells.
	await get_tree().process_frame

	var w: int = GameConstants.GRID_WIDTH
	var h: int = GameConstants.GRID_HEIGHT

	# Layers positioned at origin so cell (0,0) maps to pixels (0..CELL_SIZE).
	assert(playfield.position == Vector2.ZERO, "Playfield offset: %s" % playfield.position)
	assert(floor_layer.position == Vector2.ZERO, "Floor layer offset: %s" % floor_layer.position)
	assert(wall_layer.position == Vector2.ZERO, "Wall layer offset: %s" % wall_layer.position)

	# Floor: 20x15 grid, no gaps.
	var floor_cells := floor_layer.get_used_cells()
	assert(floor_cells.size() == w * h, "Floor cell count expected %d got %d" % [w * h, floor_cells.size()])
	for x in range(w):
		for y in range(h):
			var cell := Vector2i(x, y)
			assert(floor_layer.get_cell_source_id(cell) == 0, "Floor source mismatch at %s" % cell)
			assert(floor_layer.get_cell_atlas_coords(cell) == Vector2i(0, 0), "Floor atlas mismatch at %s" % cell)

	# TileMapLayer.map_to_local returns tile CENTER. (0,0) tile center = (16, 16) for 32px cells.
	var center := floor_layer.map_to_local(Vector2i(0, 0))
	assert(center == Vector2(16, 16), "Cell (0,0) center expected (16,16) got %s" % center)
	var center_last := floor_layer.map_to_local(Vector2i(w - 1, h - 1))
	assert(center_last == Vector2((w - 1) * 32 + 16, (h - 1) * 32 + 16), "Far cell center mismatch %s" % center_last)

	# Walls: continuous border around the play area.
	var wall_cells := wall_layer.get_used_cells()
	var expected_walls := 2 * (w + 2) + 2 * h
	assert(wall_cells.size() == expected_walls, "Wall cell count expected %d got %d" % [expected_walls, wall_cells.size()])

	# Every border cell present, every wall cell uses source 0 / atlas (0,0).
	for x in range(-1, w + 1):
		var top := Vector2i(x, -1)
		var bot := Vector2i(x, h)
		assert(wall_layer.get_cell_source_id(top) == 0, "Missing top wall at %s" % top)
		assert(wall_layer.get_cell_source_id(bot) == 0, "Missing bottom wall at %s" % bot)
	for y in range(0, h):
		var left := Vector2i(-1, y)
		var right := Vector2i(w, y)
		assert(wall_layer.get_cell_source_id(left) == 0, "Missing left wall at %s" % left)
		assert(wall_layer.get_cell_source_id(right) == 0, "Missing right wall at %s" % right)

	# Floor and walls do not overlap.
	for c in floor_cells:
		assert(c not in wall_cells, "Floor/wall overlap at %s" % c)

	# Each layer's tile_set is a fresh resource sized 32x32 with one source.
	for layer in [floor_layer, wall_layer]:
		var ts: TileSet = layer.tile_set
		assert(ts != null, "Tile set missing")
		assert(ts.tile_size == Vector2i(32, 32), "Tile size mismatch: %s" % ts.tile_size)
		assert(ts.get_source_count() == 1, "Source count mismatch: %d" % ts.get_source_count())
		var src := ts.get_source(0) as TileSetAtlasSource
		assert(src != null, "Atlas source missing")
		assert(src.has_tile(Vector2i(0, 0)), "Atlas tile (0,0) missing")

	# Far corner walls present (covers both border iterations meeting at corners).
	for corner in [Vector2i(-1, -1), Vector2i(w, -1), Vector2i(-1, h), Vector2i(w, h)]:
		assert(corner in wall_cells, "Missing corner wall at %s" % corner)

	print("OK: all Playfield tests passed")
	get_tree().quit(0)
