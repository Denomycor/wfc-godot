class_name HorizontalSplitFitness
extends GAFitnessStrategy

var _map_size: Vector2i

func _init(map_size: Vector2i) -> void:
	_map_size = map_size

func label() -> String:
	return "horizontal-split"

# Grass rewarded in the top half, dirt in the bottom half.
# Score is proportional to distance from the split (stronger bias near edges).
# Diversity gate prevents all-grass or all-dirt collapse.
func calculate(individual: PackedInt32Array) -> float:
	var n_grass := 0
	var n_dirt := 0
	var score := 0.0
	for i in individual.size():
		var y := i / _map_size.x
		var norm_y := float(y) / (_map_size.y - 1)
		var t := individual[i]
		if t == 1:
			score += 1.0 - norm_y
			n_grass += 1
		elif t == 0:
			score += norm_y
			n_dirt += 1
	var n := float(individual.size())
	var min_each := 0.05 * n
	var diversity := minf(n_grass / min_each, 1.0) * minf(n_dirt / min_each, 1.0)
	return (score / n) * diversity

func report(best_genome: PackedInt32Array) -> void:
	super.report(best_genome)
	var half := _map_size.y / 2
	var top_grass := 0; var top_total := 0
	var bot_dirt := 0; var bot_total := 0
	for i in best_genome.size():
		var y := i / _map_size.x
		if y < half:
			top_total += 1
			if best_genome[i] == 1: top_grass += 1
		else:
			bot_total += 1
			if best_genome[i] == 0: bot_dirt += 1
	print("  top-half grass: %.1f%%  bottom-half dirt: %.1f%%  (want both high)" % [
		top_grass * 100.0 / top_total if top_total > 0 else 0.0,
		bot_dirt  * 100.0 / bot_total if bot_total > 0 else 0.0])
