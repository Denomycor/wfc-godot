extends Node2D

@onready var tilemap: TileMapLayer = $TileMapLayer


func linear_to_2d(map_size: Vector2i, i: int) -> Vector2i:
	var x := i % map_size.x
	var y := floori(i as float / map_size.x)
	return Vector2i(x, y)


func _ready() -> void:

	var weights := PackedFloat64Array([3,3,1,1,1])

	var wfc := WFCEngine2D.make_generator(
		Vector2i(20,20),
		weights,
		randi(),
		false
	)

	var edge_90 := wfc.generate_variant_rule(2, WFCEngine2D.Variants.ROT90)
	var edge_180 := wfc.generate_variant_rule(2, WFCEngine2D.Variants.ROT180)
	var edge_270 := wfc.generate_variant_rule(2, WFCEngine2D.Variants.ROT270)
	wfc.set_weight(2, 0.25)
	wfc.set_weight(edge_90, 0.25)
	wfc.set_weight(edge_180, 0.25)
	wfc.set_weight(edge_270, 0.25)

	# tile 3 all rotations
	var outer_90 := wfc.generate_variant_rule(3, WFCEngine2D.Variants.ROT90)
	var outer_180 := wfc.generate_variant_rule(3, WFCEngine2D.Variants.ROT180)
	var outer_270 := wfc.generate_variant_rule(3, WFCEngine2D.Variants.ROT270)
	wfc.set_weight(3, 0.25)
	wfc.set_weight(outer_90, 0.25)
	wfc.set_weight(outer_180, 0.25)
	wfc.set_weight(outer_270, 0.25)

	# tile 4 all rotations
	var inner_90 := wfc.generate_variant_rule(4, WFCEngine2D.Variants.ROT90)
	var inner_180 := wfc.generate_variant_rule(4, WFCEngine2D.Variants.ROT180)
	var inner_270 := wfc.generate_variant_rule(4, WFCEngine2D.Variants.ROT270)
	wfc.set_weight(4, 0.25)
	wfc.set_weight(inner_90, 0.25)
	wfc.set_weight(inner_180, 0.25)
	wfc.set_weight(inner_270, 0.25)

	wfc.change_all_constraint_rule(false)

	var sides = [
		["D", "D", "D", "D"], # 0 - dirt
		["G", "G", "G", "G"], # 1 - grass
		["D", "DG", "G", "GD"], # 2 - edge horizontal
		["GD", "DG", "G", "G"], # 3 - outer corner top-left grass
		["DG", "GD", "D", "D"], # 4 - inner corner top-left grass notch

		# rotations of 2
		["GD", "D", "DG", "G"], # 5 - 90°
		["G", "GD", "D", "DG"], # 6 - 180°
		["DG", "G", "GD", "D"], # 7 - 270°

		# rotations of 3
		["G", "GD", "DG", "G"], # 8 - 90°
		["G", "G", "GD", "DG"], # 9 - 180°
		["DG", "G", "G", "GD"], # 10 - 270°

		# rotations of 4
		["D", "DG", "GD", "D"], # 11 - 90°
		["D", "D", "DG", "GD"], # 12 - 180°
		["GD", "D", "D", "DG"], # 13 - 270°
	]
	
	apply_constraints(sides, wfc)

	wfc.init()
	var success := wfc.run()
	
	print(wfc.validate())

	if success:
		var result := wfc.get_result()
		print(result)

		for i in range(result.size()):
			var cell := linear_to_2d(wfc.size, i)
			place_tile(cell, result[i])


const DIRS := [
	WFCEngine2D.Directions.UP,
	WFCEngine2D.Directions.RIGHT,
	WFCEngine2D.Directions.DOWN,
	WFCEngine2D.Directions.LEFT
]


const OPPOSITE := {
	WFCEngine2D.Directions.UP: WFCEngine2D.Directions.DOWN,
	WFCEngine2D.Directions.RIGHT: WFCEngine2D.Directions.LEFT,
	WFCEngine2D.Directions.DOWN: WFCEngine2D.Directions.UP,
	WFCEngine2D.Directions.LEFT: WFCEngine2D.Directions.RIGHT,
}

func apply_constraints(sides: Array, wfc: WFCEngine2D):
	for a in range(sides.size()):
		for b in range(sides.size()):

			for dir in DIRS:
				var a_side: String = sides[a][dir]
				var b_side: String = sides[b][OPPOSITE[dir]]

				# reverse using GDScript slicing
				if a_side == b_side.reverse():
					wfc.change_constraint_rule(a, dir, b, true)


enum TileTransform {
	ROTATE_0 = 0,
	ROTATE_90 = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H,
	ROTATE_180 = TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V,
	ROTATE_270 = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V,
}


func place_tile(cell: Vector2i, idx: int) -> void:
	if(idx == 5):
		tilemap.set_cell(cell, 0, Vector2i(2,0), TileTransform.ROTATE_90)
	elif(idx == 6):
		tilemap.set_cell(cell, 0, Vector2i(2,0), TileTransform.ROTATE_180)
	elif(idx == 7):
		tilemap.set_cell(cell, 0, Vector2i(2,0), TileTransform.ROTATE_270)
	elif(idx == 8):
		tilemap.set_cell(cell, 0, Vector2i(3,0), TileTransform.ROTATE_90)
	elif(idx == 9):
		tilemap.set_cell(cell, 0, Vector2i(3,0), TileTransform.ROTATE_180)
	elif(idx == 10):
		tilemap.set_cell(cell, 0, Vector2i(3,0), TileTransform.ROTATE_270)
	elif(idx == 11):
		tilemap.set_cell(cell, 0, Vector2i(4,0), TileTransform.ROTATE_90)
	elif(idx == 12):
		tilemap.set_cell(cell, 0, Vector2i(4,0), TileTransform.ROTATE_180)
	elif(idx == 13):
		tilemap.set_cell(cell, 0, Vector2i(4,0), TileTransform.ROTATE_270)
	else:
		tilemap.set_cell(cell, 0, Vector2i(idx,0))

