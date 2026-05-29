extends Node2D

@onready var tilemap: TileMapLayer = $TileMapLayer

const MAP_SIZE        := Vector2i(16, 16)
const POPULATION_SIZE := 20
const MAX_GENERATIONS := 100
const BOOST_FACTOR    := 120.0
const NOISE           := 0.15  # fraction of cells flipped per seed map


func _make_circle() -> PackedInt32Array:
	var m := PackedInt32Array()
	m.resize(MAP_SIZE.x * MAP_SIZE.y)
	var cx := (MAP_SIZE.x - 1) * 0.5
	var cy := (MAP_SIZE.y - 1) * 0.5
	var r2 := pow(MAP_SIZE.x * 0.3, 2)
	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			var dx := float(x) - cx
			var dy := float(y) - cy
			m[y * MAP_SIZE.x + x] = 1 if (dx * dx + dy * dy <= r2) else 0
	return m


func _circle_fitness(individual: PackedInt32Array) -> float:
	var cx := (MAP_SIZE.x - 1) * 0.5
	var cy := (MAP_SIZE.y - 1) * 0.5
	var r2 := pow(MAP_SIZE.x * 0.3, 2)
	var score := 0.0
	for i in range(individual.size()):
		var x := i % MAP_SIZE.x
		var y := i / MAP_SIZE.x
		var dx := float(x) - cx
		var dy := float(y) - cy
		var inside := (dx * dx + dy * dy) <= r2
		var tile := individual[i]
		if (inside and tile == 1) or (not inside and tile == 0):
			score += 1.0
	return score / individual.size()


func _on_generation_ended(gen: int) -> void:
	if gen % 10 == 0:
		print("  gen %d" % gen)


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = randi()

	# Seed population: perfect circles with NOISE fraction of cells flipped
	var examples: Array = []
	for _k in range(POPULATION_SIZE):
		var m := _make_circle()
		for i in range(m.size()):
			if rng.randf() < NOISE:
				m[i] = m[i] ^ 1
		examples.append(m)

	var ga := GAWFCEngine2D.make_generator(MAP_SIZE, MAX_GENERATIONS, POPULATION_SIZE, randi(), BOOST_FACTOR)
	ga.set_fitness_callable(_circle_fitness)
	ga.generation_ended.connect(_on_generation_ended)
	ga.init_examples(examples)

	print("GA-WFC circle demo: %d gens, pop %d…" % [MAX_GENERATIONS, POPULATION_SIZE])
	var t0 := Time.get_ticks_msec()
	var result: Array = ga.run()
	var elapsed := (Time.get_ticks_msec() - t0) / 1000.0

	var best_genome: PackedInt32Array = result[0]
	var best_fitness: float = result[1]
	print("Done in %.1f s  |  best fitness = %.3f" % [elapsed, best_fitness])

	# tile 0 → atlas (0,0) dirt/outer, tile 1 → atlas (1,0) grass/inner
	for i in range(best_genome.size()):
		var x := i % MAP_SIZE.x
		var y := i / MAP_SIZE.x
		tilemap.set_cell(Vector2i(x, y), 0, Vector2i(best_genome[i], 0))

