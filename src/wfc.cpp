#include "wfc.hpp"
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

void WFCGenerator2D::init_wave_state(){
    for(auto& cell : m_wave_state){
        for(auto [tile,_] : m_tile_weights){
            cell[tile] = true;
        }
    }
}

void WFCGenerator2D::_bind_methods() {
}

