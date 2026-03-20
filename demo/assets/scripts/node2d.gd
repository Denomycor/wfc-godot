extends Node2D

@onready var tilemap: TileMapLayer = $TileMapLayer


func _ready() -> void:
	print("hello")
	var weights := PackedFloat64Array([1,1,1])
	var wfc := WFCEngine2D.make_generator(Vector2i(20,20), weights, false)
	wfc.stepped.connect(func(_wfc: WFCEngine2D):
		print("step")
	)
	wfc.finished.connect(func(_wfc: WFCEngine2D):
		print("finished")
	)

	# Not needed
	wfc.set_label(0, "sand")
	wfc.set_label(1, "water")
	wfc.set_label(2, "grass")

	wfc.change_constraint_rule(1, WFCEngine2D.Directions.UP, 2, false)
	wfc.change_constraint_rule(1, WFCEngine2D.Directions.DOWN, 2, false)
	wfc.change_constraint_rule(1, WFCEngine2D.Directions.LEFT, 2, false)
	wfc.change_constraint_rule(1, WFCEngine2D.Directions.RIGHT, 2, false)

	wfc.init()
	var failed := wfc.run()

	if(!failed):
		var result := wfc.get_result()
		for i in range(result.size()):
			var cell := Vector2i(i % wfc.get_size().x, floor(i as float / wfc.get_size().y))
			place_tile(cell, result[i])


func place_tile(cell: Vector2i, idx: int,) -> void:
	tilemap.set_cell(cell, idx, Vector2i.ZERO)


