#pragma once
#include "godot_cpp/classes/ref_counted.hpp"
#include "../wfc-cpp/include/ga_wfc.hpp"
#include "godot_cpp/variant/array.hpp"
#include "godot_cpp/variant/packed_int32_array.hpp"
#include "godot_cpp/variant/typed_array.hpp"
#include "godot_cpp/variant/vector2i.hpp"


namespace godot {

class GAWFCEngine2D : public RefCounted {
	GDCLASS(GAWFCEngine2D, RefCounted)
private:
    class GAWFCCustom : public wfc::GAWFC {
    public:
        GAWFCEngine2D* owner;
        using wfc::GAWFC::GAWFC;
        double fitness(const GenomeT& result) const override;
    };

    GAWFCCustom m_generator;
    bool valid;

protected:
    static void _bind_methods();
    void _setup();

public:
    GAWFCEngine2D();
    GAWFCEngine2D(const wfc::Vec3u& wfc_size, int max_generations, int population_size, int seed, double boost_factor);
    ~GAWFCEngine2D() = default;

    static Ref<GAWFCEngine2D> make_generator(const Vector2i& wfc_size, int max_generations, int population_size, int seed, double boost_factor);

    virtual double fitness(const PackedInt32Array& individual);
    virtual Array run();
    virtual void init_examples(const TypedArray<PackedInt32Array>& examples);

    Vector2i get_wfc_size() const;
    int get_max_generations() const;
    int get_population_size() const;
    int get_boost_factor() const;
    int get_generation_count() const;
    bool is_valid() const;

};

}

// vim: ts=4 sts=4 sw=4 et

