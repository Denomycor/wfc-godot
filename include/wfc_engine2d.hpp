#pragma once

#include "godot_cpp/classes/ref_counted.hpp"
#include "../wfc-cpp/include/wfc.hpp"
#include "godot_cpp/variant/vector2i.hpp"


namespace godot {

class WFCEngine2D : public RefCounted{
	GDCLASS(WFCEngine2D, RefCounted)
private:
	wfc::WFC wfc_generator;
	bool valid;

protected:
	static void _bind_methods();

public:
	enum STATUS {
		NOT_INIT_STATUS,
		READY_STATUS,
		RUNNING_STATUS,
		FINISHED_STATUS,
		CONTRADICTION_STATUS,
		NOT_VALID_STATUS,
	};

	WFCEngine2D();
	~WFCEngine2D();
	
	STATUS get_status();
	Vector2i select_cell();
	void collapse_cell(const Vector2i& cell);
	void propagate_constraints(const Vector2i& cell);

    void init();
    bool step();
    bool run();

};

}

// vim: ts=4 sts=4 sw=4 et

