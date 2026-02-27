#pragma once

#include "godot_cpp/classes/ref_counted.hpp"
#include "array2d.hpp"
#include <unordered_map>
#include "godot_cpp/variant/dictionary.hpp"

namespace godot{

class WFCGenerator2D : public RefCounted {
	GDCLASS(WFCGenerator2D, RefCounted)
	
private:
	using WaveState_T = Array2D<std::unordered_map<int, bool>>;
	using TileWeights_T = std::unordered_map<int, double>;

	WaveState_T m_wave_state;
	TileWeights_T m_tile_weights;
	int m_test;

	void init_wave_state();

protected:
	static void _bind_methods();

public:
	WFCGenerator2D();
	WFCGenerator2D(int width, int height, const Dictionary& tile_wights);

	void test();
	int get_test();
	void set_test(int p);
};

}

