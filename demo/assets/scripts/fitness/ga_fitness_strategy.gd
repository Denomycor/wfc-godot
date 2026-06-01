class_name GAFitnessStrategy

func calculate(_individual: PackedInt32Array) -> float:
	return 0.0

func label() -> String:
	return "unknown"

func report(best_genome: PackedInt32Array) -> void:
	var n := float(best_genome.size())
	var ng := 0; var nd := 0
	for t in best_genome:
		if t == 1: ng += 1
		elif t == 0: nd += 1
	print("  grass: %.1f%%  dirt: %.1f%%  transition: %.1f%%" % [ng/n*100, nd/n*100, (n-ng-nd)/n*100])
