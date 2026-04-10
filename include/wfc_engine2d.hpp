#pragma once

#include "abstract_wfc.hpp"
#include "godot_cpp/classes/ref_counted.hpp"
#include "../wfc-cpp/include/wfc.hpp"
#include "godot_cpp/variant/packed_float64_array.hpp"
#include "godot_cpp/variant/packed_int32_array.hpp"
#include "godot_cpp/variant/string.hpp"
#include "godot_cpp/variant/vector2i.hpp"


namespace godot {

class WFCEngine2D : public RefCounted {
	GDCLASS(WFCEngine2D, RefCounted)
private:
	wfc::WFC wfc_generator;
	bool valid;

protected:
	static void _bind_methods();
    void _setup();

public:
	enum Status {
		NOT_INIT_STATUS = wfc::AbstractWFC::NOT_INIT_STATUS,
		READY_STATUS = wfc::AbstractWFC::READY_STATUS,
		RUNNING_STATUS = wfc::AbstractWFC::RUNNING_STATUS,
		FINISHED_STATUS = wfc::AbstractWFC::FINISHED_STATUS,
		CONTRADICTION_STATUS = wfc::AbstractWFC::CONTRADICTION_STATUS,
		NOT_VALID_STATUS,
	};

    enum Directions {
        UP = wfc::UP,
        DOWN = wfc::DOWN,
        LEFT = wfc::LEFT,
        RIGHT = wfc::RIGHT,
    };
    
    enum Variants {
        IDENTITY = wfc::IDENTITY,
        ROT90 = wfc::ROT90,
        ROT180 = wfc::ROT180,
        ROT270 = wfc::ROT270,
        VFLIP = wfc::VFLIP,
        HFLIP = wfc::HFLIP,
        HFLIPROT90 = wfc::HFLIPROT90,
        HFLIPROT270 = wfc::HFLIPROT270,
    };

    static Ref<WFCEngine2D> make_generator(const Vector2i& size, const PackedFloat64Array& weights, int seed, bool periodic);

	WFCEngine2D(const wfc::Vec3u& size, const wfc::TileWeights& weights, int seed, bool periodic);
    WFCEngine2D();
	~WFCEngine2D();
	
	Status get_status();
    Vector2i get_size();

	Vector2i select_cell();
	void collapse_cell(const Vector2i& cell);
	void propagate_constraints(const Vector2i& cell);
    
    void change_constraint_rule(int idx, Directions direction, int n_idx, bool allow);
    void generate_variant_rule(int idx, Variants variant);

    void set_label(int idx, const String& label);
    String get_label(int idx);

    PackedInt32Array get_result();

    void init();
    bool step();
    bool run();

};

}

// vim: ts=4 sts=4 sw=4 et

