extends Node2D

@onready var tilemap: TileMapLayer = $TileMapLayer


func _ready() -> void:
	print("hello")
	var weights := PackedFloat64Array([1,1,1,1,1])
	var wfc := WFCEngine2D.make_generator(Vector2i(20,20), weights, false, 0)
	wfc.stepped.connect(func(_wfc: WFCEngine2D):
		print("step")
	)
	wfc.finished.connect(func(_wfc: WFCEngine2D):
		print("finished")
	)

	##--------- #0

	wfc.change_constraint_rule(0, WFCEngine2D.Directions.DOWN, 1, false)
	wfc.change_constraint_rule(0, WFCEngine2D.Directions.UP, 1, false)
	wfc.change_constraint_rule(0, WFCEngine2D.Directions.LEFT, 1, false)
	wfc.change_constraint_rule(0, WFCEngine2D.Directions.RIGHT, 1, false)
	
	wfc.change_constraint_rule(0, WFCEngine2D.Directions.UP, 2, false)
	wfc.change_constraint_rule(0, WFCEngine2D.Directions.LEFT, 2, false)
	wfc.change_constraint_rule(0, WFCEngine2D.Directions.RIGHT, 2, false)

	wfc.change_constraint_rule(0, WFCEngine2D.Directions.DOWN, 3, false)
	wfc.change_constraint_rule(0, WFCEngine2D.Directions.UP, 3, false)
	wfc.change_constraint_rule(0, WFCEngine2D.Directions.LEFT, 3, false)
	wfc.change_constraint_rule(0, WFCEngine2D.Directions.RIGHT, 3, false)

	wfc.change_constraint_rule(0, WFCEngine2D.Directions.DOWN, 2, false)
	wfc.change_constraint_rule(0, WFCEngine2D.Directions.LEFT, 2, false)
	
	##--------- #1

	wfc.change_constraint_rule(1, WFCEngine2D.Directions.DOWN, 2, false)
	wfc.change_constraint_rule(1, WFCEngine2D.Directions.LEFT, 2, false)
	wfc.change_constraint_rule(1, WFCEngine2D.Directions.RIGHT, 2, false)

	wfc.change_constraint_rule(1, WFCEngine2D.Directions.DOWN, 3, false)
	wfc.change_constraint_rule(1, WFCEngine2D.Directions.LEFT, 3, false)

	wfc.change_constraint_rule(1, WFCEngine2D.Directions.DOWN, 4, false)
	wfc.change_constraint_rule(1, WFCEngine2D.Directions.UP, 4, false)
	wfc.change_constraint_rule(1, WFCEngine2D.Directions.LEFT, 4, false)
	wfc.change_constraint_rule(1, WFCEngine2D.Directions.RIGHT, 4, false)

	##-------- #2

	wfc.change_constraint_rule(2, WFCEngine2D.Directions.DOWN, 2, false)
	wfc.change_constraint_rule(2, WFCEngine2D.Directions.UP, 2, false)

	wfc.change_constraint_rule(2, WFCEngine2D.Directions.DOWN, 3, false)
	wfc.change_constraint_rule(2, WFCEngine2D.Directions.RIGHT, 3, false)
	wfc.change_constraint_rule(2, WFCEngine2D.Directions.UP, 3, false)

	wfc.change_constraint_rule(2, WFCEngine2D.Directions.DOWN, 4, false)
	wfc.change_constraint_rule(2, WFCEngine2D.Directions.RIGHT, 4, false)
	wfc.change_constraint_rule(2, WFCEngine2D.Directions.LEFT, 4, false)

	##-------- #3

	wfc.change_constraint_rule(3, WFCEngine2D.Directions.DOWN, 3, false)
	wfc.change_constraint_rule(3, WFCEngine2D.Directions.UP, 3, false)
	wfc.change_constraint_rule(3, WFCEngine2D.Directions.RIGHT, 3, false)
	wfc.change_constraint_rule(3, WFCEngine2D.Directions.LEFT, 3, false)

	wfc.change_constraint_rule(3, WFCEngine2D.Directions.DOWN, 4, false)
	wfc.change_constraint_rule(3, WFCEngine2D.Directions.UP, 4, false)
	wfc.change_constraint_rule(3, WFCEngine2D.Directions.RIGHT, 4, false)
	wfc.change_constraint_rule(3, WFCEngine2D.Directions.LEFT, 4, false)

	##-------- #4

	wfc.change_constraint_rule(4, WFCEngine2D.Directions.DOWN, 4, false)
	wfc.change_constraint_rule(4, WFCEngine2D.Directions.UP, 4, false)
	wfc.change_constraint_rule(4, WFCEngine2D.Directions.RIGHT, 4, false)
	wfc.change_constraint_rule(4, WFCEngine2D.Directions.LEFT, 4, false)
	

	##------- #Variants

	wfc.generate_variant_rule(2, WFCEngine2D.Variants.ROT90)
	wfc.generate_variant_rule(2, WFCEngine2D.Variants.ROT180)
	wfc.generate_variant_rule(2, WFCEngine2D.Variants.ROT270)

	wfc.generate_variant_rule(3, WFCEngine2D.Variants.ROT90)
	wfc.generate_variant_rule(3, WFCEngine2D.Variants.ROT180)
	wfc.generate_variant_rule(3, WFCEngine2D.Variants.ROT270)

	wfc.generate_variant_rule(4, WFCEngine2D.Variants.ROT90)
	wfc.generate_variant_rule(4, WFCEngine2D.Variants.ROT180)
	wfc.generate_variant_rule(4, WFCEngine2D.Variants.ROT270)

	wfc.init()
	var failed := wfc.run()

	if(!failed):
		var result := wfc.get_result()
		for i in range(result.size()):
			var cell := Vector2i(i % wfc.get_size().x, floor(i as float / wfc.get_size().y))
			place_tile(cell, result[i])


func place_tile(cell: Vector2i, idx: int,) -> void:
	tilemap.set_cell(cell, idx, Vector2i.ZERO)


