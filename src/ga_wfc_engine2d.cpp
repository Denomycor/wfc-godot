#include "ga_wfc_engine2d.hpp"
#include "godot_cpp/core/class_db.hpp"
#include "godot_cpp/core/memory.hpp"
#include "godot_cpp/variant/array.hpp"
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

    ClassDB::bind_method(D_METHOD("get_wfc_size"), &GAWFCEngine2D::get_wfc_size);
    ClassDB::bind_method(D_METHOD("get_max_generations"), &GAWFCEngine2D::get_max_generations);
    ClassDB::bind_method(D_METHOD("get_population_size"), &GAWFCEngine2D::get_population_size);
    ClassDB::bind_method(D_METHOD("get_boost_factor"), &GAWFCEngine2D::get_boost_factor);
    ClassDB::bind_method(D_METHOD("get_generation_count"), &GAWFCEngine2D::get_generation_count);
    ClassDB::bind_method(D_METHOD("is_valid"), &GAWFCEngine2D::is_valid);

    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2I, "wfc_size"), "", "get_wfc_size");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "max_generations"), "", "get_max_generations");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "population_size"), "", "get_population_size");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "boost_factor"), "", "get_boost_factor");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "generation_count"), "", "get_generation_count");
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "valid"), "", "is_valid");

    ADD_SIGNAL(MethodInfo("generation_ended", PropertyInfo(Variant::INT, "generation_count")));
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
    m_generator.generation_ended.connect([this](int generation_count){
        emit_signal("generation_ended", generation_count);
    });
}


double GAWFCEngine2D::fitness(const PackedInt32Array& individual) {
    // this method must be overwriten
    return 0.0;
}


Array GAWFCEngine2D::run(){
    auto[genome, fit] = m_generator.run();
    PackedInt32Array buffer;
    for(auto v : genome){
	buffer.append(v);
    }
    return {buffer, fit};
};


void GAWFCEngine2D::init_examples(const TypedArray<PackedInt32Array>& examples){
    std::vector<wfc::GAWFC::GenomeT> b_examples;
    b_examples.reserve(examples.size());
    auto[x,y,z] = m_generator.get_wfc_size();
    
    for(int i = 0; i < examples.size(); i++){

        wfc::Array3D<unsigned int> buffer(x,y,z);
	auto&& e = static_cast<PackedInt32Array>(examples[i]);
        for(int j=0; j < e.size(); j++){
            buffer.get_linear(j) = e[j];
        }
	
	b_examples.emplace_back(buffer);
    }

    m_generator.init_examples(b_examples);
}


Vector2i GAWFCEngine2D::get_wfc_size() const {
    auto[x,y,z] = m_generator.get_wfc_size();
    return Vector2i(x,y);
}


int GAWFCEngine2D::get_max_generations() const {
    return m_generator.get_max_generations();
}


int GAWFCEngine2D::get_population_size() const {
    return m_generator.get_population_size();
}


int GAWFCEngine2D::get_boost_factor() const {
    return m_generator.get_boost_factor();
}


int GAWFCEngine2D::get_generation_count() const {
    return m_generator.get_generation_count();
}


bool GAWFCEngine2D::is_valid() const {
    return valid;
}

