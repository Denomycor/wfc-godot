#pragma once
#include "godot_cpp/classes/ref_counted.hpp"
#include "../wfc-cpp/include/ga_wfc.hpp"


namespace godot {

class GAWFCEngine2D : public RefCounted {
	GDCLASS(GAWFCEngine2D, RefCounted)
private:
    class GAWFCCustom : public wfc::GAWFC {
    public:
        using wfc::GAWFC::GAWFC;
        double fitness(const GenomeT& result) const override;
    };

    GAWFCCustom generator;
};

}

// vim: ts=4 sts=4 sw=4 et

