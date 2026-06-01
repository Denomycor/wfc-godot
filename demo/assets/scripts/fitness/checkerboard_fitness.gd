class_name CheckerboardFitness
extends GAFitnessStrategy

var _map_size: Vector2i
var _block_size: int

func _init(map_size: Vector2i, block_size: int = 8) -> void:
	_map_size = map_size
	_block_size = block_size

func label() -> String:
	return "checkerboard-%d" % _block_size

# Coarse checkerboard: block_size×block_size regions alternate grass/dirt.
# Diversity gate prevents all-grass or all-dirt collapse.
func calculate(individual: PackedInt32Array) -> float:
	var n_grass := 0
	var n_dirt := 0
	var score := 0.0
	for i in individual.size():
		var x := i % _map_size.x
		var y := i / _map_size.x
		var bx := x / _block_size
		var by := y / _block_size
		var want_grass := (bx + by) % 2 == 0
		var t := individual[i]
		if t == 1:
			n_grass += 1
			if want_grass: score += 1.0
		elif t == 0:
			n_dirt += 1
			if not want_grass: score += 1.0
	var n := float(individual.size())
	var min_each := 0.05 * n
	var diversity := minf(n_grass / min_each, 1.0) * minf(n_dirt / min_each, 1.0)
	return (score / n) * diversity

func report(best_genome: PackedInt32Array) -> void:
	super.report(best_genome)
	var match_count := 0
	for i in best_genome.size():
		var x := i % _map_size.x
		var y := i / _map_size.x
		var bx := x / _block_size
		var by := y / _block_size
		var want_grass := (bx + by) % 2 == 0
		var t := best_genome[i]
		if (want_grass and t == 1) or (not want_grass and t == 0):
			match_count += 1
	print("  checkerboard match: %.1f%%  (block size %d, want high)" % [
		match_count * 100.0 / best_genome.size(), _block_size])
