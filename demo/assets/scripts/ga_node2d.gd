extends Node2D

@onready var tilemap: TileMapLayer = $TileMapLayer

const MAP_SIZE        := Vector2i(48, 48)
const POPULATION_SIZE := 20
const MAX_GENERATIONS := 100
const BOOST_FACTOR    := 120.0
const NOISE           := 0.10

enum FitnessMode { GRASS_EDGE, HORIZONTAL_SPLIT, CHECKERBOARD, DIAGONAL_SPLIT, RINGS, CROSS }
const ACTIVE_FITNESS := FitnessMode.DIAGONAL_SPLIT

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


# Seed map: grass on edges, dirt in center, transition tiles in between.
# Includes all 5 base tiles so GAWFC.setup() initialises weights/constraints to size 5.
func _make_radial(rng: RandomNumberGenerator) -> PackedInt32Array:
	var m := PackedInt32Array()
	m.resize(MAP_SIZE.x * MAP_SIZE.y)
	var cx := (MAP_SIZE.x - 1) * 0.5
	var cy := (MAP_SIZE.y - 1) * 0.5
	var max_dist := sqrt(cx * cx + cy * cy)
	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			var dx := float(x) - cx
			var dy := float(y) - cy
			var dist := sqrt(dx * dx + dy * dy) / max_dist
			var tile: int
			if dist > 0.6:
				tile = 1                         # grass
			elif dist < 0.35:
				tile = 0                         # dirt
			else:
				tile = rng.randi_range(2, 4)     # transition
			if rng.randf() < NOISE:
				tile = rng.randi_range(0, 4)
			m[y * MAP_SIZE.x + x] = tile
	return m


func _make_fitness_strategy() -> GAFitnessStrategy:
	match ACTIVE_FITNESS:
		FitnessMode.GRASS_EDGE:
			return GrassEdgeFitness.new(MAP_SIZE)
		FitnessMode.HORIZONTAL_SPLIT:
			return HorizontalSplitFitness.new(MAP_SIZE)
		FitnessMode.CHECKERBOARD:
			return CheckerboardFitness.new(MAP_SIZE, 8)
		FitnessMode.DIAGONAL_SPLIT:
			return DiagonalSplitFitness.new(MAP_SIZE)
		FitnessMode.RINGS:
			return RingFitness.new(MAP_SIZE, 3)
		FitnessMode.CROSS:
			return CrossFitness.new(MAP_SIZE, 6)
	return GrassEdgeFitness.new(MAP_SIZE)


func _on_generation_ended(gen: int) -> void:
	if gen % 10 == 0:
		print("  gen %d" % gen)


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = randi()

	var examples: Array = []
	for _k in range(POPULATION_SIZE):
		examples.append(_make_radial(rng))

	var strategy := _make_fitness_strategy()

	var ga := GAWFCEngine2D.make_generator(MAP_SIZE, MAX_GENERATIONS, POPULATION_SIZE, randi(), BOOST_FACTOR)
	ga.set_fitness_callable(strategy.calculate)
	ga.generation_ended.connect(_on_generation_ended)

	# init_examples derives initial weights/constraints from the 5-tile seed maps
	ga.init_examples(examples)

	# Override weights to match node2d.gd baseline
	ga.set_weight(0, 3.0)
	ga.set_weight(1, 3.0)
	ga.set_weight(2, 1.0)
	ga.set_weight(3, 1.0)
	ga.set_weight(4, 1.0)

	# Generate rotated variants for the three transition tiles (same as node2d.gd)
	for base in [2, 3, 4]:
		var r90  := ga.generate_variant_rule(base, WFCEngine2D.Variants.ROT90)
		var r180 := ga.generate_variant_rule(base, WFCEngine2D.Variants.ROT180)
		var r270 := ga.generate_variant_rule(base, WFCEngine2D.Variants.ROT270)
		ga.set_weight(base, 0.25)
		ga.set_weight(r90,  0.25)
		ga.set_weight(r180, 0.25)
		ga.set_weight(r270, 0.25)

	# Override all constraints, then apply the same constraint table as node2d.gd
	ga.change_all_constraint_rule(false)

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
	apply_constraints(sides, ga)

	print("GA-WFC %s demo: %d gens, pop %d…" % [strategy.label(), MAX_GENERATIONS, POPULATION_SIZE])
	var t0 := Time.get_ticks_msec()
	var result: Array = ga.run()
	var elapsed := (Time.get_ticks_msec() - t0) / 1000.0

	var best_genome: PackedInt32Array = result[0]
	var best_fitness: float = result[1]
	print("Done in %.1f s  |  best fitness = %.3f" % [elapsed, best_fitness])

	strategy.report(best_genome)

	for i in range(best_genome.size()):
		var x := i % MAP_SIZE.x
		var y := i / MAP_SIZE.x
		place_tile(Vector2i(x, y), best_genome[i])


func apply_constraints(sides: Array, gen) -> void:
	for a in range(sides.size()):
		for b in range(sides.size()):
			for dir in DIRS:
				var a_side: String = sides[a][dir]
				var b_side: String = sides[b][OPPOSITE[dir]]
				if a_side == b_side.reverse():
					gen.change_constraint_rule(a, dir, b, true)


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
