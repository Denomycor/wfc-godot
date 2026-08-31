extends Node2D

@onready var tilemap: TileMapLayer = $TileMapLayer

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


enum TileTransform {
	ROTATE_0 = 0,
	ROTATE_90 = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H,
	ROTATE_180 = TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V,
	ROTATE_270 = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V,
}


func linear_to_2d(map_size: Vector2i, i: int) -> Vector2i:
	var x := i % map_size.x
	var y := floori(i as float / map_size.x)
	return Vector2i(x, y)


func _ready() -> void:
	var weights := PackedFloat64Array([3, 3, 1, 1, 1, 0.5, 0.5])
	var wfc := WFCEngine2D.make_generator(Vector2i(20,20), weights, randi(), false)

	for base in [2, 3, 4]:
		var r90  := wfc.generate_variant_rule(base, WFCEngine2D.Variants.ROT90)
		var r180 := wfc.generate_variant_rule(base, WFCEngine2D.Variants.ROT180)
		var r270 := wfc.generate_variant_rule(base, WFCEngine2D.Variants.ROT270)
		wfc.set_weight(base, 0.25)
		wfc.set_weight(r90,  0.25)
		wfc.set_weight(r180, 0.25)
		wfc.set_weight(r270, 0.25)

	for base in [5, 6]:
		var r90 := wfc.generate_variant_rule(base, WFCEngine2D.Variants.ROT90)
		wfc.set_weight(base, 0.25)
		wfc.set_weight(r90,  0.25)

	wfc.change_all_constraint_rule(false)

	var sides := [
		["D",  "D",  "D",  "D" ],  # 0:  dirt
		["G",  "G",  "G",  "G" ],  # 1:  grass
		["D",  "DG", "G",  "GD"],  # 2:  atlas(2,0) rot0
		["GD", "DG", "G",  "G" ],  # 3:  atlas(3,0) rot0
		["DG", "GD", "D",  "D" ],  # 4:  atlas(4,0) rot0
		["GD", "DG", "GD", "DG"],  # 5:  atlas(5,0) rot0  (S-curve; tile6 is its rot90)
		["DG", "GD", "DG", "GD"],  # 6:  atlas(6,0) rot0  (Z-curve; tile5 is its rot90)
		["GD", "D",  "DG", "G" ],  # 7:  atlas(2,0) rot90
		["G",  "GD", "D",  "DG"],  # 8:  atlas(2,0) rot180
		["DG", "G",  "GD", "D" ],  # 9:  atlas(2,0) rot270
		["G",  "GD", "DG", "G" ],  # 10: atlas(3,0) rot90
		["G",  "G",  "GD", "DG"],  # 11: atlas(3,0) rot180
		["DG", "G",  "G",  "GD"],  # 12: atlas(3,0) rot270
		["D",  "DG", "GD", "D" ],  # 13: atlas(4,0) rot90
		["D",  "D",  "DG", "GD"],  # 14: atlas(4,0) rot180
		["GD", "D",  "D",  "DG"],  # 15: atlas(4,0) rot270
		["DG", "GD", "DG", "GD"],  # 16: atlas(5,0) rot90
		["GD", "DG", "GD", "DG"],  # 17: atlas(6,0) rot90
	]

	apply_constraints(sides, wfc)

	var success := false
	var attempts := 0
	while not success and attempts < 50:
		wfc.init()
		success = wfc.run()
		attempts += 1

	if success:
		print("WFC succeeded on attempt ", attempts)
		var result := wfc.get_result()
		for i in range(result.size()):
			var cell := linear_to_2d(wfc.size, i)
			place_tile(cell, result[i])
	else:
		print("WFC could not find a periodic solution in ", attempts, " attempts.")


func apply_constraints(sides: Array, wfc: WFCEngine2D) -> void:
	for a in range(sides.size()):
		for b in range(sides.size()):
			for dir in DIRS:
				var a_side: String = sides[a][dir]
				var b_side: String = sides[b][OPPOSITE[dir]]
				if a_side == b_side.reverse():
					wfc.change_constraint_rule(a, dir, b, true)


func place_tile(cell: Vector2i, idx: int) -> void:
	match idx:
		7:  tilemap.set_cell(cell, 0, Vector2i(2, 0), TileTransform.ROTATE_90)
		8:  tilemap.set_cell(cell, 0, Vector2i(2, 0), TileTransform.ROTATE_180)
		9:  tilemap.set_cell(cell, 0, Vector2i(2, 0), TileTransform.ROTATE_270)
		10: tilemap.set_cell(cell, 0, Vector2i(3, 0), TileTransform.ROTATE_90)
		11: tilemap.set_cell(cell, 0, Vector2i(3, 0), TileTransform.ROTATE_180)
		12: tilemap.set_cell(cell, 0, Vector2i(3, 0), TileTransform.ROTATE_270)
		13: tilemap.set_cell(cell, 0, Vector2i(4, 0), TileTransform.ROTATE_90)
		14: tilemap.set_cell(cell, 0, Vector2i(4, 0), TileTransform.ROTATE_180)
		15: tilemap.set_cell(cell, 0, Vector2i(4, 0), TileTransform.ROTATE_270)
		16: tilemap.set_cell(cell, 0, Vector2i(5, 0), TileTransform.ROTATE_90)
		17: tilemap.set_cell(cell, 0, Vector2i(6, 0), TileTransform.ROTATE_90)
		_:  tilemap.set_cell(cell, 0, Vector2i(idx, 0))

