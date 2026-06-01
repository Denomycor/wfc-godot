class_name RingFitness
extends GAFitnessStrategy

var _map_size: Vector2i
var _num_rings: int

func _init(map_size: Vector2i, num_rings: int = 3) -> void:
	_map_size = map_size
	_num_rings = num_rings

func label() -> String:
	return "rings-%d" % _num_rings

# Concentric rings alternate grass (even) and dirt (odd).
# Ring 0 is the center disc; ring num_rings-1 is the outer edge.
func calculate(individual: PackedInt32Array) -> float:
	var cx := (_map_size.x - 1) * 0.5
	var cy := (_map_size.y - 1) * 0.5
	var max_dist := sqrt(cx * cx + cy * cy)
	var n_grass := 0
	var n_dirt := 0
	var score := 0.0
	for i in individual.size():
		var x := i % _map_size.x
		var y := i / _map_size.x
		var dist := sqrt(pow(x - cx, 2) + pow(y - cy, 2)) / max_dist
		var ring := mini(int(dist * _num_rings), _num_rings - 1)
		var want_grass := ring % 2 == 0
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
	var cx := (_map_size.x - 1) * 0.5
	var cy := (_map_size.y - 1) * 0.5
	var max_dist := sqrt(cx * cx + cy * cy)
	var match_count := 0
	for i in best_genome.size():
		var x := i % _map_size.x
		var y := i / _map_size.x
		var dist := sqrt(pow(x - cx, 2) + pow(y - cy, 2)) / max_dist
		var ring := mini(int(dist * _num_rings), _num_rings - 1)
		var want_grass := ring % 2 == 0
		var t := best_genome[i]
		if (want_grass and t == 1) or (not want_grass and t == 0):
			match_count += 1
	print("  ring match: %.1f%%  (%d rings, want high)" % [
		match_count * 100.0 / best_genome.size(), _num_rings])
