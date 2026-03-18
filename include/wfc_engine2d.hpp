#pragma once

#include "abstract_wfc.hpp"
#include "godot_cpp/classes/ref_counted.hpp"
#include "../wfc-cpp/include/wfc.hpp"
#include "godot_cpp/variant/packed_float64_array.hpp"
#include "godot_cpp/variant/vector2i.hpp"


namespace godot {

class WFCEngine2D : public RefCounted{
	GDCLASS(WFCEngine2D, RefCounted)
private:
	wfc::WFC wfc_generator;
	bool valid;

    void _setup();

protected:
	static void _bind_methods();

public:
	enum STATUS {
		NOT_INIT_STATUS = wfc::AbstractWFC::NOT_INIT_STATUS,
		READY_STATUS = wfc::AbstractWFC::READY_STATUS,
		RUNNING_STATUS = wfc::AbstractWFC::RUNNING_STATUS,
		FINISHED_STATUS = wfc::AbstractWFC::FINISHED_STATUS,
		CONTRADICTION_STATUS = wfc::AbstractWFC::CONTRADICTION_STATUS,
		NOT_VALID_STATUS,
	};

    enum DIRECTIONS {
        UP = wfc::UP,
        DOWN = wfc::DOWN,
        LEFT = wfc::LEFT,
        RIGHT = wfc::RIGHT,
    };

    static Ref<WFCEngine2D> make_generator(const Vector2i& size, const PackedFloat64Array& weights, bool periodic);

	WFCEngine2D(const wfc::Vec3u& size, const wfc::TileWeights& weights, bool periodic);
    WFCEngine2D();
	~WFCEngine2D();
	
	STATUS get_status();
    Vector2i get_size();

	Vector2i select_cell();
	void collapse_cell(const Vector2i& cell);
	void propagate_constraints(const Vector2i& cell);
    
    void change_constraint_rule(int idx, DIRECTIONS direction, int n_idx, bool allow);

    void init();
    bool step();
    bool run();

};

}

// vim: ts=4 sts=4 sw=4 et

