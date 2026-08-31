extends Node

@onready var tilemap: TileMapLayer = $TileMapLayer

const DIRS := [
	WFCEngine2D.Directions.UP,
	WFCEngine2D.Directions.RIGHT,
	WFCEngine2D.Directions.DOWN,
	WFCEngine2D.Directions.LEFT
]

# Tile IDs (CW from top-left of the atlas):
# 0: sand     -> atlas (0,0)
# 1: mountain -> atlas (1,0)
# 2: grass    -> atlas (1,1)
# 3: ocean    -> atlas (0,1)
#
# ATLAS_POS[i] doubles as the (dx, dy) offset of tile i within each 2x2 TileMap block.

const ATLAS_POS := [
	Vector2i(0, 0),  # sand
	Vector2i(1, 0),  # mountain
	Vector2i(1, 1),  # grass
	Vector2i(0, 1),  # ocean
]

var wfc: WFCEngine2D

@export var draw_offset := Vector2i(-15, -10)
@export var se: int = 0


func linear_to_2d(map_size: Vector2i, i: int) -> Vector2i:
	var x := i % map_size.x
	var y := floori(i as float / map_size.x)
	return Vector2i(x, y)


func _ready() -> void:
	var weights := PackedFloat64Array([1.0, 1.0, 1.0, 1.0])
	wfc = WFCEngine2D.make_generator(Vector2i(10, 10), weights, se, false)

	wfc.change_all_constraint_rule(false)

	var compatible := [
		[3, 3],  # ocean-ocean
		[3, 0],  # ocean-sand
		[0, 0],  # sand-sand
		[0, 2],  # sand-grass
		[2, 2],  # grass-grass
		[2, 1],  # grass-mountain
		[1, 1],  # mountain-mountain
	]

	for pair in compatible:
		var a: int = pair[0]
		var b: int = pair[1]
		for dir in DIRS:
			wfc.change_constraint_rule(a, dir, b, true)
			wfc.change_constraint_rule(b, dir, a, true)

	wfc.init()
	draw_wave()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var status := wfc.get_status()
	if event.keycode == KEY_ENTER:
		if status == WFCEngine2D.FINISHED_STATUS or status == WFCEngine2D.CONTRADICTION_STATUS:
			wfc.init()
		else:
			wfc.step()
		draw_wave()
	elif event.keycode == KEY_RIGHT:
		if status == WFCEngine2D.FINISHED_STATUS or status == WFCEngine2D.CONTRADICTION_STATUS:
			wfc.init()
		else:
			wfc.run()
		draw_wave()


func draw_wave() -> void:
	var map_size := wfc.size
	for i in range(map_size.x * map_size.y):
		var wfc_cell := linear_to_2d(map_size, i)
		var options := wfc.get_cell_options(wfc_cell)
		if options.size() == 1:
			tilemap.set_cell(draw_offset + wfc_cell * 2, 1, ATLAS_POS[options[0]])
			for tile_id in range(4):
				if ATLAS_POS[tile_id] != Vector2i(0, 0):
					tilemap.erase_cell(draw_offset + wfc_cell * 2 + ATLAS_POS[tile_id])
		else:
			var options_set := {}
			for opt in options:
				options_set[opt] = true
			for tile_id in range(4):
				var map_cell : Vector2i = draw_offset + wfc_cell * 2 + ATLAS_POS[tile_id]
				if options_set.has(tile_id):
					tilemap.set_cell(map_cell, 0, ATLAS_POS[tile_id])
				else:
					tilemap.erase_cell(map_cell)
