#include "ga_wfc_engine2d.hpp"
#include "godot_cpp/core/class_db.hpp"
#include "godot_cpp/core/memory.hpp"
#include "godot_cpp/variant/packed_int32_array.hpp"
#include "godot_cpp/variant/vector2i.hpp"
#include "utils.hpp"
#include <vector>

using namespace godot;


void GAWFCEngine2D::_bind_methods() {
    ClassDB::bind_static_method("GAWFCEngine2D", D_METHOD("make_generator", "wfc_size", "max_generations", "population_size", "seed", "boost_factor"), &GAWFCEngine2D::make_generator);
    ClassDB::bind_method(D_METHOD("fitness", "individual"), &GAWFCEngine2D::fitness);
    ClassDB::bind_method(D_METHOD("run"), &GAWFCEngine2D::run);
    ClassDB::bind_method(D_METHOD("init_examples", "examples"), &GAWFCEngine2D::init_examples);
}


double GAWFCEngine2D::GAWFCCustom::fitness(const GenomeT& result) const {
    PackedInt32Array buffer;
    for(auto v : result){
	buffer.append(v);
    }
    return owner->fitness(buffer);
}


Ref<GAWFCEngine2D> GAWFCEngine2D::make_generator(const Vector2i& wfc_size, int max_generations, int population_size, int seed, double boost_factor){
    wfc::Vec3u size(wfc_size.x, wfc_size.y, 1);
    return memnew(GAWFCEngine2D(size, max_generations, population_size, seed, boost_factor));
}


GAWFCEngine2D::GAWFCEngine2D(const wfc::Vec3u& wfc_size, int max_generations, int population_size, int seed, double boost_factor)
: m_generator(wfc_size, max_generations, population_size, seed, boost_factor), valid(true)
{
    _setup();
}


GAWFCEngine2D::GAWFCEngine2D()
:m_generator(wfc::Vec3u(1,1,1), 1, 1, 1, 1), valid(false)
{
    _setup();
}


void GAWFCEngine2D::_setup(){
    m_generator.owner = this;
}


double GAWFCEngine2D::fitness(const PackedInt32Array& individual) {
    // this method must be overwriten
    return 0.0;
}


PackedInt32Array GAWFCEngine2D::run(){
    auto[genome, fit] = m_generator.run();
    PackedInt32Array buffer;
    for(auto v : genome){
	buffer.append(v);
    }
    return buffer;
};


void GAWFCEngine2D::init_examples(const TypedArray<PackedInt32Array>& examples){
    std::vector<wfc::GAWFC::GenomeT> b_examples;
    b_examples.reserve(examples.size());
    auto[x,y,z] = m_generator.get_wfc_size();
    
    for(int i = 0; i < examples.size(); i++){

        wfc::Array3D<unsigned int> buffer(x,y,z);
	PackedInt32Array* e = Object::cast_to<PackedInt32Array>(examples[i]);
        for(int j=0; j < e->size(); j++){
            buffer.get_linear(j) = (*e)[j];
        }
	
	b_examples.emplace_back(buffer);
    }

    m_generator.init_examples(b_examples);
}

