extends Node2D

@onready var tilemap: TileMapLayer = $TileMapLayer

const CHUNK_SIZE := Vector2i(20, 20)
const GRID_W := 100
const GRID_H := 100

func _ready() -> void:
	var io := MemoryChunkWFCIO.new()
	# 0=water, 1=sand, 2=grass; slightly higher sand weight to encourage it as buffer
	var weights := PackedFloat64Array([1.0, 1.5, 1.0])
	var gen := ChunkWFCEngine2D.make_generator(CHUNK_SIZE, weights, io, 8, 42)

	# All adjacencies allowed by default; forbid water<->grass in every direction
	gen.change_tile_neighbor_constraint_rule(0, 2, false)

	gen.successful_chunk.connect(_on_chunk_done)
	gen.failed_chunk.connect(_on_chunk_failed)

	gen.generate_range(Vector2i(0, 0), Vector2i(GRID_W, GRID_H))


func _on_chunk_done(coords: Vector2i, data: PackedInt32Array) -> void:
	var offset := coords * CHUNK_SIZE
	for i in data.size():
		var local := Vector2i(i % CHUNK_SIZE.x, i / CHUNK_SIZE.x)
		# source_id matches tile ID: 0=water, 1=sand, 2=grass
		tilemap.set_cell(offset + local, data[i], Vector2i(0, 0))


func _on_chunk_failed(coords: Vector2i) -> void:
	print("Chunk generation failed: ", coords)
