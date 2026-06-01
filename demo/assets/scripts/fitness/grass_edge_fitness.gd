class_name GrassEdgeFitness
extends GAFitnessStrategy

var _map_size: Vector2i

func _init(map_size: Vector2i) -> void:
	_map_size = map_size

func label() -> String:
	return "grass-edge"

# Grass rewarded far from center, dirt rewarded near center.
# Diversity gate ensures neither pure type dominates.
func calculate(individual: PackedInt32Array) -> float:
	var cx := (_map_size.x - 1) * 0.5
	var cy := (_map_size.y - 1) * 0.5
	var max_dist := sqrt(cx * cx + cy * cy)
	var score := 0.0
	var n_grass := 0
	var n_dirt := 0
	for i in individual.size():
		var x := i % _map_size.x
		var y := i / _map_size.x
		var dx := float(x) - cx
		var dy := float(y) - cy
		var dist := sqrt(dx * dx + dy * dy) / max_dist
		var tile := individual[i]
		if tile == 1:
			score += dist * dist
			n_grass += 1
		elif tile == 0:
			score += (1.0 - dist) * (1.0 - dist)
			n_dirt += 1
	var n := float(individual.size())
	var min_each := 0.05 * n
	var diversity := minf(n_grass / min_each, 1.0) * minf(n_dirt / min_each, 1.0)
	return (score / n) * diversity

func report(best_genome: PackedInt32Array) -> void:
	super.report(best_genome)
	var cx := (_map_size.x - 1) * 0.5
	var cy := (_map_size.y - 1) * 0.5
	var max_dist := sqrt(cx * cx + cy * cy)
	var ng := 0; var nd := 0; var sum_dg := 0.0; var sum_dd := 0.0
	for i in best_genome.size():
		var x := i % _map_size.x; var y := i / _map_size.x
		var dist := sqrt(pow(x - cx, 2) + pow(y - cy, 2)) / max_dist
		if best_genome[i] == 1: ng += 1; sum_dg += dist
		elif best_genome[i] == 0: nd += 1; sum_dd += dist
	print("  mean dist  grass=%.3f  dirt=%.3f  (want grass > dirt)" % [
		sum_dg / ng if ng > 0 else 0.0,
		sum_dd / nd if nd > 0 else 0.0])
