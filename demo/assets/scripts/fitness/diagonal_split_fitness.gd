class_name DiagonalSplitFitness
extends GAFitnessStrategy

var _map_size: Vector2i

func _init(map_size: Vector2i) -> void:
	_map_size = map_size

func label() -> String:
	return "diagonal-split"

# Upper-right triangle = grass, lower-left = dirt.
# Score is proportional to signed distance from the main diagonal,
# so cells deep in their correct region contribute more.
func calculate(individual: PackedInt32Array) -> float:
	var n_grass := 0
	var n_dirt := 0
	var score := 0.0
	var scale := float(_map_size.x - 1)
	for i in individual.size():
		var x := i % _map_size.x
		var y := i / _map_size.x
		# bias in [-1, 1]: positive = upper-right, negative = lower-left
		var bias := float(x - y) / scale
		var t := individual[i]
		if t == 1:
			score += (1.0 + bias) * 0.5
			n_grass += 1
		elif t == 0:
			score += (1.0 - bias) * 0.5
			n_dirt += 1
	var n := float(individual.size())
	var min_each := 0.05 * n
	var diversity := minf(n_grass / min_each, 1.0) * minf(n_dirt / min_each, 1.0)
	return (score / n) * diversity

func report(best_genome: PackedInt32Array) -> void:
	super.report(best_genome)
	var upper_grass := 0; var upper_total := 0
	var lower_dirt := 0; var lower_total := 0
	for i in best_genome.size():
		var x := i % _map_size.x
		var y := i / _map_size.x
		if x > y:
			upper_total += 1
			if best_genome[i] == 1: upper_grass += 1
		elif x < y:
			lower_total += 1
			if best_genome[i] == 0: lower_dirt += 1
	print("  upper-right grass: %.1f%%  lower-left dirt: %.1f%%  (want both high)" % [
		upper_grass * 100.0 / upper_total if upper_total > 0 else 0.0,
		lower_dirt  * 100.0 / lower_total if lower_total > 0 else 0.0])
