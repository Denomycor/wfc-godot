#include "wfc_engine2d.hpp"
#include "abstract_wfc.hpp"
#include "godot_cpp/classes/global_constants.hpp"
#include "godot_cpp/core/binder_common.hpp"
#include "godot_cpp/core/object.hpp"
#include "godot_cpp/core/property_info.hpp"
#include "godot_cpp/variant/packed_float64_array.hpp"
#include "godot_cpp/variant/packed_int32_array.hpp"
#include "godot_cpp/variant/variant.hpp"
#include "godot_cpp/variant/vector2i.hpp"
#include "wfc.hpp"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;


void WFCEngine2D::_bind_methods() {
    BIND_ENUM_CONSTANT(NOT_INIT_STATUS);
    BIND_ENUM_CONSTANT(READY_STATUS);
    BIND_ENUM_CONSTANT(RUNNING_STATUS);
    BIND_ENUM_CONSTANT(FINISHED_STATUS);
    BIND_ENUM_CONSTANT(CONTRADICTION_STATUS);
    BIND_ENUM_CONSTANT(NOT_VALID_STATUS);

    BIND_ENUM_CONSTANT(UP);
    BIND_ENUM_CONSTANT(DOWN);
    BIND_ENUM_CONSTANT(LEFT);
    BIND_ENUM_CONSTANT(RIGHT);

    BIND_ENUM_CONSTANT(IDENTITY);
    BIND_ENUM_CONSTANT(ROT90);
    BIND_ENUM_CONSTANT(ROT180);
    BIND_ENUM_CONSTANT(ROT270);
    BIND_ENUM_CONSTANT(VFLIP);
    BIND_ENUM_CONSTANT(HFLIP);
    BIND_ENUM_CONSTANT(HFLIPROT90);
    BIND_ENUM_CONSTANT(HFLIPROT270);

    ClassDB::bind_method(D_METHOD("get_status"), &WFCEngine2D::get_status);
    ClassDB::bind_method(D_METHOD("get_size"), &WFCEngine2D::get_size);
    ClassDB::bind_method(D_METHOD("select_cell"), &WFCEngine2D::select_cell);
    ClassDB::bind_method(D_METHOD("collapse_cell", "cell"), &WFCEngine2D::collapse_cell);
    ClassDB::bind_method(D_METHOD("propagate_constraints", "cell"), &WFCEngine2D::propagate_constraints);
    ClassDB::bind_method(D_METHOD("change_constraint_rule", "idx", "direction", "n_idx", "allow"), &WFCEngine2D::change_constraint_rule);
    ClassDB::bind_method(D_METHOD("init"), &WFCEngine2D::init);
    ClassDB::bind_method(D_METHOD("step"), &WFCEngine2D::step);
    ClassDB::bind_method(D_METHOD("run"), &WFCEngine2D::run);
    ClassDB::bind_static_method("WFCEngine2D", D_METHOD("make_generator", "size", "weights", "seed", "periodic"), &WFCEngine2D::make_generator);
    ClassDB::bind_method(D_METHOD("generate_variant_rule", "idx", "variant"), &WFCEngine2D::generate_variant_rule);
    ClassDB::bind_method(D_METHOD("get_label", "idx"), &WFCEngine2D::get_label);
    ClassDB::bind_method(D_METHOD("set_label", "idx", "label"), &WFCEngine2D::set_label);
    ClassDB::bind_method(D_METHOD("get_result"), &WFCEngine2D::get_result);

	ADD_PROPERTY(PropertyInfo(Variant::INT, "status", PROPERTY_HINT_ENUM, "NOT_INIT_STATUS,READY_STATUS,RUNNING_STATUS,FINISHED_STATUS,CONTRADICTION_STATUS,NOT_VALID_STATUS"), "", "get_status");
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR2I, "size"), "", "get_size");

    ADD_SIGNAL(MethodInfo("stepped", PropertyInfo(Variant::OBJECT, "wfc", PROPERTY_HINT_RESOURCE_TYPE, "WFCEngine2D")));
    ADD_SIGNAL(MethodInfo("finished", PropertyInfo(Variant::OBJECT, "wfc", PROPERTY_HINT_RESOURCE_TYPE, "WFCEngine2D")));
}


WFCEngine2D::Status WFCEngine2D::get_status(){
	if(valid){
        return static_cast<Status>(wfc_generator.get_status());
    } else{
        return WFCEngine2D::NOT_VALID_STATUS;
    }
}


Vector2i WFCEngine2D::get_size(){
    return { static_cast<int32_t>(wfc_generator.get_wave().get_width()),
        static_cast<int32_t>(wfc_generator.get_wave().get_height()) };
}


Ref<WFCEngine2D> WFCEngine2D::make_generator(const Vector2i &size, const PackedFloat64Array &weights, int seed, bool periodic){
    wfc::TileWeights convert(weights.size());
    for(const auto& e : weights){
        convert.emplace_back(static_cast<double>(e));
    }
    return memnew(WFCEngine2D({static_cast<unsigned int>(size.x), static_cast<unsigned int>(size.y), 1}, convert, seed, periodic));
}


WFCEngine2D::WFCEngine2D(const wfc::Vec3u& size, const wfc::TileWeights& weights, int seed, bool periodic)
: wfc_generator(size, weights, seed, periodic), valid(true)
{
    _setup();
}


WFCEngine2D::WFCEngine2D()
: wfc_generator({1,1,1}, {1}), valid(false)
{
    _setup();
}


WFCEngine2D::~WFCEngine2D(){}


void WFCEngine2D::_setup(){
    wfc_generator.stepped.connect([this](...){
        emit_signal("stepped", Ref<WFCEngine2D>(this));
    });
    wfc_generator.finished.connect([this](...){
        emit_signal("finished", Ref<WFCEngine2D>(this));
    });
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


void WFCEngine2D::change_constraint_rule(int idx, Directions direction, int n_idx, bool allow){
    wfc_generator.constraints.change_rule(idx, static_cast<wfc::Directions>(direction), n_idx, allow);
}


void WFCEngine2D::generate_variant_rule(int idx, Variants variant){
    wfc_generator.constraints.generate_variant(idx, static_cast<wfc::Variants2D>(variant), wfc_generator.weights, wfc_generator.labels);
}


void WFCEngine2D::set_label(int idx, const String& label){
    wfc_generator.labels[idx] = label.utf8().get_data();
}


String WFCEngine2D::get_label(int idx){
    return String::utf8(wfc_generator.labels[idx].c_str());
}


PackedInt32Array WFCEngine2D::get_result(){
    auto res = wfc_generator.get_result();
    PackedInt32Array out;
    for(const auto& e : res){
        out.push_back(e);
    }
    return out;
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

VARIANT_ENUM_CAST(WFCEngine2D::Status)
VARIANT_ENUM_CAST(WFCEngine2D::Directions)
VARIANT_ENUM_CAST(WFCEngine2D::Variants)

// vim: ts=4 sts=4 sw=4 et

