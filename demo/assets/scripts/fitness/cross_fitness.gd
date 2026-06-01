class_name CrossFitness
extends GAFitnessStrategy

var _map_size: Vector2i
var _arm_width: int

func _init(map_size: Vector2i, arm_width: int = 6) -> void:
	_map_size = map_size
	_arm_width = arm_width

func label() -> String:
	return "cross-%d" % _arm_width

# Central horizontal + vertical bands = dirt; four corner quadrants = grass.
# arm_width controls how many cells wide each arm of the cross is.
func calculate(individual: PackedInt32Array) -> float:
	var hx := _map_size.x / 2
	var hy := _map_size.y / 2
	var n_grass := 0
	var n_dirt := 0
	var score := 0.0
	for i in individual.size():
		var x := i % _map_size.x
		var y := i / _map_size.x
		var in_cross := absi(x - hx) < _arm_width or absi(y - hy) < _arm_width
		var t := individual[i]
		if t == 1:
			n_grass += 1
			if not in_cross: score += 1.0
		elif t == 0:
			n_dirt += 1
			if in_cross: score += 1.0
	var n := float(individual.size())
	var min_each := 0.05 * n
	var diversity := minf(n_grass / min_each, 1.0) * minf(n_dirt / min_each, 1.0)
	return (score / n) * diversity

func report(best_genome: PackedInt32Array) -> void:
	super.report(best_genome)
	var hx := _map_size.x / 2
	var hy := _map_size.y / 2
	var cross_dirt := 0; var cross_total := 0
	var quad_grass := 0; var quad_total := 0
	for i in best_genome.size():
		var x := i % _map_size.x
		var y := i / _map_size.x
		var in_cross := absi(x - hx) < _arm_width or absi(y - hy) < _arm_width
		var t := best_genome[i]
		if in_cross:
			cross_total += 1
			if t == 0: cross_dirt += 1
		else:
			quad_total += 1
			if t == 1: quad_grass += 1
	print("  cross dirt: %.1f%%  quadrant grass: %.1f%%  (want both high, arm width %d)" % [
		cross_dirt * 100.0 / cross_total if cross_total > 0 else 0.0,
		quad_grass * 100.0 / quad_total  if quad_total  > 0 else 0.0,
		_arm_width])
