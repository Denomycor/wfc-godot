extends Node2D

@onready var tilemap: TileMapLayer = $TileMapLayer

const CHUNK_SIZE := Vector2i(20, 20)
const GRID_W := 10
const GRID_H := 10

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
	ROTATE_0   = 0,
	ROTATE_90  = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H,
	ROTATE_180 = TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V,
	ROTATE_270 = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V,
}


func _ready() -> void:
	var io := MemoryChunkWFCIO.new()
	var weights := PackedFloat64Array([3, 3, 1, 1, 1])
	var gen := ChunkWFCEngine2D.make_generator(CHUNK_SIZE, weights, io, 8, randi())

	for base in [2, 3, 4]:
		var r90  := gen.generate_variant_rule(base, WFCEngine2D.Variants.ROT90)
		var r180 := gen.generate_variant_rule(base, WFCEngine2D.Variants.ROT180)
		var r270 := gen.generate_variant_rule(base, WFCEngine2D.Variants.ROT270)
		gen.set_weight(base, 0.25)
		gen.set_weight(r90,  0.25)
		gen.set_weight(r180, 0.25)
		gen.set_weight(r270, 0.25)

	gen.change_all_constraint_rule(false)

	var sides := [
		["D", "D", "D", "D"],
		["G", "G", "G", "G"],
		["D", "DG", "G", "GD"],
		["GD", "DG", "G", "G"],
		["DG", "GD", "D", "D"],
		["GD", "D", "DG", "G"],
		["G", "GD", "D", "DG"],
		["DG", "G", "GD", "D"],
		["G", "GD", "DG", "G"],
		["G", "G", "GD", "DG"],
		["DG", "G", "G", "GD"],
		["D", "DG", "GD", "D"],
		["D", "D", "DG", "GD"],
		["GD", "D", "D", "DG"],
	]

	apply_constraints(sides, gen)

	gen.successful_chunk.connect(_on_chunk_done)
	gen.failed_chunk.connect(_on_chunk_failed)

	gen.generate_range(Vector2i(0, 0), Vector2i(GRID_W, GRID_H))


func apply_constraints(sides: Array, gen) -> void:
	for a in range(sides.size()):
		for b in range(sides.size()):
			for dir in DIRS:
				var a_side: String = sides[a][dir]
				var b_side: String = sides[b][OPPOSITE[dir]]
				if a_side == b_side.reverse():
					gen.change_constraint_rule(a, dir, b, true)


func _on_chunk_done(coords: Vector2i, data: PackedInt32Array) -> void:
	var offset := coords * CHUNK_SIZE
	for i in data.size():
		var local := Vector2i(i % CHUNK_SIZE.x, i / CHUNK_SIZE.x)
		place_tile(offset + local, data[i])


func place_tile(cell: Vector2i, idx: int) -> void:
	match idx:
		5:  tilemap.set_cell(cell, 0, Vector2i(2, 0), TileTransform.ROTATE_90)
		6:  tilemap.set_cell(cell, 0, Vector2i(2, 0), TileTransform.ROTATE_180)
		7:  tilemap.set_cell(cell, 0, Vector2i(2, 0), TileTransform.ROTATE_270)
		8:  tilemap.set_cell(cell, 0, Vector2i(3, 0), TileTransform.ROTATE_90)
		9:  tilemap.set_cell(cell, 0, Vector2i(3, 0), TileTransform.ROTATE_180)
		10: tilemap.set_cell(cell, 0, Vector2i(3, 0), TileTransform.ROTATE_270)
		11: tilemap.set_cell(cell, 0, Vector2i(4, 0), TileTransform.ROTATE_90)
		12: tilemap.set_cell(cell, 0, Vector2i(4, 0), TileTransform.ROTATE_180)
		13: tilemap.set_cell(cell, 0, Vector2i(4, 0), TileTransform.ROTATE_270)
		_:  tilemap.set_cell(cell, 0, Vector2i(idx, 0))


func _on_chunk_failed(coords: Vector2i) -> void:
	print("Chunk generation failed: ", coords)
