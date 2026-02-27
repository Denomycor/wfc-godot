#include "wfc.hpp"
#include "godot_cpp/core/class_db.hpp"
#include "godot_cpp/core/object.hpp"
#include "godot_cpp/core/property_info.hpp"
#include "godot_cpp/variant/array.hpp"

using namespace godot;

WFCGenerator2D::WFCGenerator2D(int width, int height, const Dictionary& tile_weights)
:m_wave_state(width, height), m_tile_weights()
{
	// Convert godot dictionary to std dictionary
	Array keys = tile_weights.keys();
	for(int i=0; i<keys.size(); i++){
		m_tile_weights[keys[i]] = tile_weights[keys[i]];
	} 

}

WFCGenerator2D::WFCGenerator2D()
:m_wave_state(1, 1), m_tile_weights()
{}

void WFCGenerator2D::init_wave_state(){
    for(auto& cell : m_wave_state){
        for(auto [tile,_] : m_tile_weights){
            cell[tile] = true;
        }
    }
}

void WFCGenerator2D::test(){

}

int WFCGenerator2D::get_test(){
    return m_test;
}

void WFCGenerator2D::set_test(int p){
    m_test = p;
}

void WFCGenerator2D::_bind_methods() {
    ClassDB::bind_method(D_METHOD("test"), &WFCGenerator2D::test);
    ClassDB::bind_method(D_METHOD("get_test"), &WFCGenerator2D::get_test);
    ClassDB::bind_method(D_METHOD("set_test", "p_amplitude"), &WFCGenerator2D::set_test);

    ADD_PROPERTY(PropertyInfo(Variant::INT, "m_tilt"), "set_test", "get_test");
}

