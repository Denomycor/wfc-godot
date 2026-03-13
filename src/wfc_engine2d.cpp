#include "wfc_engine2d.hpp"
#include "abstract_wfc.hpp"
#include "godot_cpp/classes/global_constants.hpp"
#include "godot_cpp/core/binder_common.hpp"
#include "godot_cpp/variant/vector2i.hpp"
#include "wfc.hpp"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;


void WFCEngine2D::_bind_methods() {
    BIND_ENUM_CONSTANT(WFCEngine2D::NOT_INIT_STATUS);
    BIND_ENUM_CONSTANT(WFCEngine2D::READY_STATUS);
    BIND_ENUM_CONSTANT(WFCEngine2D::RUNNING_STATUS);
    BIND_ENUM_CONSTANT(WFCEngine2D::FINISHED_STATUS);
    BIND_ENUM_CONSTANT(WFCEngine2D::CONTRADICTION_STATUS);
    BIND_ENUM_CONSTANT(WFCEngine2D::NOT_VALID_STATUS);

    ClassDB::bind_method(D_METHOD("get_status"), &WFCEngine2D::get_status);

	ADD_PROPERTY(PropertyInfo(Variant::INT, "status", PROPERTY_HINT_ENUM, "NOT_INIT_STATUS,READY_STATUS,RUNNING_STATUS,FINISHED_STATUS,CONTRADICTION_STATUS,NOT_VALID_STATUS"), "", "get_status");
}


WFCEngine2D::STATUS WFCEngine2D::get_status(){
    if(!valid){
        return WFCEngine2D::NOT_VALID_STATUS;
    }

	switch (wfc_generator.get_status()) {
	case wfc::AbstractWFC::NOT_INIT_STATUS:
		return WFCEngine2D::NOT_INIT_STATUS;
	case wfc::AbstractWFC::READY_STATUS:
		return WFCEngine2D::READY_STATUS;
	case wfc::AbstractWFC::RUNNING_STATUS:
		return WFCEngine2D::RUNNING_STATUS;
	case wfc::AbstractWFC::FINISHED_STATUS:
		return WFCEngine2D::FINISHED_STATUS;
	case wfc::AbstractWFC::CONTRADICTION_STATUS:
		return WFCEngine2D::CONTRADICTION_STATUS;
	  break;
    }
}


WFCEngine2D::WFCEngine2D()
: wfc_generator({1,1,1}, {1}), valid(false)
{

}


WFCEngine2D::~WFCEngine2D(){

}


Vector2i WFCEngine2D::select_cell(){
	auto res = wfc_generator.select_cell();
	if(res.has_value()){
		auto[x,y,z] = res.value();
		return Vector2i(x,y);
	}else{
		return Vector2i(-1,-1);
	}
}


void WFCEngine2D::collapse_cell(const Vector2i& cell){
	wfc::Vec3u coords(cell.x, cell.y, 0);
	wfc_generator.collapse_cell(coords);
}


void WFCEngine2D::propagate_constraints(const Vector2i& cell){
	wfc::Vec3u coords(cell.x, cell.y, 0);
	wfc_generator.collapse_cell(coords);
}


void WFCEngine2D::init(){
    wfc_generator.init();
}


bool WFCEngine2D::step(){
    return wfc_generator.step();
}


bool WFCEngine2D::run(){
    return wfc_generator.run();
}

VARIANT_ENUM_CAST(WFCEngine2D::STATUS)

// vim: ts=4 sts=4 sw=4 et

