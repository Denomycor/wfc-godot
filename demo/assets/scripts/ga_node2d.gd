## GA-WFC demo — grass-island fitness
##
## Uses GAWFCEngine2D to evolve a 20×20 tilemap toward a "grass island"
## pattern: fully grassy in the centre, pure dirt toward the edges.
##
## Steps:
##   1. Seed the GA population by running plain WFC POPULATION_SIZE times.
##   2. Create a GAWFCEngine2D, plug in the island fitness callable.
##   3. Call init_examples() — the GA infers tile weights and adjacency
##      constraints from the seed maps (no manual constraint setup needed).
##   4. Run the GA and paint the best result on the TileMapLayer.
##
## Note: ga.run() is blocking on the main thread (the GA uses an internal
##       thread pool only for the WFC collapse step, not for fitness).
##       For production use, wrap it in a Thread.

extends Node2D

@onready var tilemap: TileMapLayer = $TileMapLayer

# ── GA parameters ─────────────────────────────────────────────────────────────
const MAP_SIZE        := Vector2i(20, 20)
const POPULATION_SIZE := 10
const MAX_GENERATIONS := 50
const BOOST_FACTOR    := 2.0   # must be > 1.0

# ── Tile grassiness (fraction of the tile that is grass) ──────────────────────
# Index = tile ID (0–13, including all rotation variants).
const GRASS_SCORE: Array[float] = [
	0.0,              # 0  – full dirt
	1.0,              # 1  – full grass
	0.5,              # 2  – edge (half grass / half dirt)
	0.75,             # 3  – outer corner  (mostly grass)
	0.25,             # 4  – inner corner notch (mostly dirt)
	0.5,  0.5,  0.5,  # 5-7  edge rotations
	0.75, 0.75, 0.75, # 8-10 outer corner rotations
	0.25, 0.25, 0.25, # 11-13 inner corner rotations
]


# ── Fitness function ───────────────────────────────────────────────────────────

## Target grass coverage at grid position (x, y):
## a Gaussian blob centred on the map — 1.0 at the centre, ~0 at corners.
func _target_grass(x: int, y: int) -> float:
	var cx := MAP_SIZE.x * 0.5
	var cy := MAP_SIZE.y * 0.5
	var dx := (x - cx) / cx   # normalised to [-1, 1]
	var dy := (y - cy) / cy
	return exp(-3.0 * (dx * dx + dy * dy))


## Island fitness: penalise mismatch between each tile's actual grassiness
## and the desired Gaussian target.  Returns 0 for a perfect match; more
## negative = worse.  The GA maximises this value.
func island_fitness(individual: PackedInt32Array) -> float:
	var score := 0.0
	for i in range(individual.size()):
		var x := i % MAP_SIZE.x
		var y := i / MAP_SIZE.x
		var tile_id := individual[i]
		if tile_id < GRASS_SCORE.size():
			var g: float = GRASS_SCORE[tile_id]
			score -= absf(g - _target_grass(x, y))
	return score


# ── WFC setup (mirrors node2d.gd) ─────────────────────────────────────────────

const DIRS := [
	WFCEngine2D.Directions.UP,
	WFCEngine2D.Directions.RIGHT,
	WFCEngine2D.Directions.DOWN,
	WFCEngine2D.Directions.LEFT,
]

const OPPOSITE := {
	WFCEngine2D.Directions.UP:    WFCEngine2D.Directions.DOWN,
	WFCEngine2D.Directions.RIGHT: WFCEngine2D.Directions.LEFT,
	WFCEngine2D.Directions.DOWN:  WFCEngine2D.Directions.UP,
	WFCEngine2D.Directions.LEFT:  WFCEngine2D.Directions.RIGHT,
}

## Create and fully configure a WFCEngine2D for the grass tileset.
func _make_wfc() -> WFCEngine2D:
	# Base weights: dirt and grass are common, transition tiles are rare.
	var weights := PackedFloat64Array([3, 3, 1, 1, 1])
	var wfc := WFCEngine2D.make_generator(MAP_SIZE, weights, randi(), false)

	# Generate rotation variants and give them equal (low) weight.
	for base in [2, 3, 4]:
		var r90  := wfc.generate_variant_rule(base, WFCEngine2D.Variants.ROT90)
		var r180 := wfc.generate_variant_rule(base, WFCEngine2D.Variants.ROT180)
		var r270 := wfc.generate_variant_rule(base, WFCEngine2D.Variants.ROT270)
		wfc.set_weight(base, 0.25)
		wfc.set_weight(r90,  0.25)
		wfc.set_weight(r180, 0.25)
		wfc.set_weight(r270, 0.25)

	# Start from a fully-forbidden constraint table, then allow valid pairs.
	wfc.change_all_constraint_rule(false)

	# Each entry: [UP_side, RIGHT_side, DOWN_side, LEFT_side]
	# "G" = grass edge, "D" = dirt edge, "GD"/"DG" = gradient edges.
	var sides := [
		["D",  "D",  "D",  "D" ],  # 0  – dirt
		["G",  "G",  "G",  "G" ],  # 1  – grass
		["D",  "DG", "G",  "GD"],  # 2  – edge
		["GD", "DG", "G",  "G" ],  # 3  – outer corner
		["DG", "GD", "D",  "D" ],  # 4  – inner corner notch
		["GD", "D",  "DG", "G" ],  # 5  – edge 90°
		["G",  "GD", "D",  "DG"],  # 6  – edge 180°
		["DG", "G",  "GD", "D" ],  # 7  – edge 270°
		["G",  "GD", "DG", "G" ],  # 8  – outer corner 90°
		["G",  "G",  "GD", "DG"],  # 9  – outer corner 180°
		["DG", "G",  "G",  "GD"],  # 10 – outer corner 270°
		["D",  "DG", "GD", "D" ],  # 11 – inner corner 90°
		["D",  "D",  "DG", "GD"],  # 12 – inner corner 180°
		["GD", "D",  "D",  "DG"],  # 13 – inner corner 270°
	]

	_apply_constraints(sides, wfc)
	return wfc


func _apply_constraints(sides: Array, wfc: WFCEngine2D) -> void:
	for a in range(sides.size()):
		for b in range(sides.size()):
			for dir in DIRS:
				var a_side: String = sides[a][dir]
				var b_side: String = sides[b][OPPOSITE[dir]]
				# Two tiles may be neighbours when a_side == reverse(b_side)
				if a_side == b_side.reverse():
					wfc.change_constraint_rule(a, dir, b, true)


## Run WFC until it finds a valid result (up to 50 retries).
func _run_wfc_once(wfc: WFCEngine2D) -> PackedInt32Array:
	for _attempt in range(50):
		wfc.init()
		if wfc.run():
			return wfc.get_result()
	return PackedInt32Array()   # empty = failure


# ── TileMap helpers (same mapping as node2d.gd) ───────────────────────────────

enum TileTransform {
	ROTATE_0   = 0,
	ROTATE_90  = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H,
	ROTATE_180 = TileSetAtlasSource.TRANSFORM_FLIP_H    | TileSetAtlasSource.TRANSFORM_FLIP_V,
	ROTATE_270 = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V,
}


func _place_tile(cell: Vector2i, idx: int) -> void:
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


# ── Progress callback ─────────────────────────────────────────────────────────

func _on_generation_ended(generation_count: int) -> void:
	print("  generation %d / %d" % [generation_count + 1, MAX_GENERATIONS])


# ── Entry point ───────────────────────────────────────────────────────────────

func _ready() -> void:
	var t0 := Time.get_ticks_msec()

	# ── 1. Generate the initial population using plain WFC ────────────────────
	print("GA-WFC: generating %d seed maps via WFC…" % POPULATION_SIZE)
	var wfc  := _make_wfc()
	var examples: Array = []

	for k in range(POPULATION_SIZE):
		var genome := _run_wfc_once(wfc)
		if genome.is_empty():
			push_error("WFC failed to generate example %d" % k)
			return
		examples.append(genome)

	print("  seed maps ready.")

	# ── 2. Create GA engine ───────────────────────────────────────────────────
	var ga := GAWFCEngine2D.make_generator(
		MAP_SIZE,
		MAX_GENERATIONS,
		POPULATION_SIZE,
		randi(),
		BOOST_FACTOR
	)

	# Inject the fitness function.  The callable is always invoked on the
	# calling thread (never from a worker thread), so GDScript is safe here.
	ga.set_fitness_callable(Callable(self, "island_fitness"))
	ga.generation_ended.connect(_on_generation_ended)

	# ── 3. Seed the GA with the WFC outputs ───────────────────────────────────
	# init_examples() derives tile weights and adjacency constraints directly
	# from the provided maps — no manual constraint setup required.
	ga.init_examples(examples)

	# ── 4. Run the GA ─────────────────────────────────────────────────────────
	print("Running GA (%d generations, population %d)…" % [MAX_GENERATIONS, POPULATION_SIZE])
	var result_arr: Array   = ga.run()
	var best_genome: PackedInt32Array = result_arr[0]
	var best_fitness: float = result_arr[1]

	var elapsed := (Time.get_ticks_msec() - t0) / 1000.0
	print("Done in %.1f s  |  best fitness = %.3f" % [elapsed, best_fitness])

	# ── 5. Paint the best genome on the tilemap ───────────────────────────────
	for i in range(best_genome.size()):
		var x := i % MAP_SIZE.x
		var y := i / MAP_SIZE.x
		_place_tile(Vector2i(x, y), best_genome[i])

