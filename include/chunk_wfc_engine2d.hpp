#pragma once

#include "godot_cpp/classes/ref_counted.hpp"
#include "godot_cpp/classes/wrapped.hpp"
#include "../wfc-cpp/include/chunk_wfc.hpp"
#include "godot_cpp/variant/packed_float64_array.hpp"
#include "godot_cpp/variant/packed_int32_array.hpp"
#include "godot_cpp/variant/string.hpp"
#include "godot_cpp/variant/vector2i.hpp"
#include <memory>


namespace godot{


class ChunkWFCIO : public RefCounted {
    GDCLASS(ChunkWFCIO, RefCounted);

protected:
	static void _bind_methods();
    ChunkWFCIO(const std::shared_ptr<wfc::ChunkWFCIO>& p_handler);

public:
    std::shared_ptr<wfc::ChunkWFCIO> handler;
    ChunkWFCIO();
    virtual ~ChunkWFCIO() = default;
};


class DiskChunkWFCIO : public ChunkWFCIO {
	GDCLASS(DiskChunkWFCIO, ChunkWFCIO)
private:
	bool valid;

protected:
	static void _bind_methods();

public:
	static Ref<DiskChunkWFCIO> open(const String& index, const String& chunks, const Vector2i& size);

	DiskChunkWFCIO(const std::filesystem::path& index_path, const std::filesystem::path& chunks_path, const wfc::Vec3u& chunk_size);
	DiskChunkWFCIO();
	~DiskChunkWFCIO();

	void flush_index();
};


class CustomChunkWFCIO : public ChunkWFCIO {
    GDCLASS(CustomChunkWFCIO, ChunkWFCIO)

private:
    wfc::Vec3u m_chunk_size;

    struct _impWFCIO : wfc::ChunkWFCIO {
        CustomChunkWFCIO* ptr;
        _impWFCIO(CustomChunkWFCIO* p) : ptr(p) {}
        std::optional<wfc::Array3D<unsigned int>> reader(const wfc::Vec3i& coords) override;
        void writer(const wfc::Vec3i& coords, const wfc::Array3D<unsigned int>& result) override;
    };

protected:
	static void _bind_methods();

public:
    CustomChunkWFCIO();

    void set_chunk_size(const Vector2i& size);
    Vector2i get_chunk_size();

    virtual PackedInt32Array reader(const Vector2i& coords);
    virtual void writer(const Vector2i& coords, const PackedInt32Array& data);
};


class ChunkWFCEngine2D : public RefCounted {
	GDCLASS(ChunkWFCEngine2D, RefCounted)
private:
	wfc::ChunkWFC wfc_generator;
	Ref<ChunkWFCIO> m_io;
	bool valid;

protected:
	static void _bind_methods();
	void _setup();

public:
	static Ref<ChunkWFCEngine2D> make_generator(const Vector2i& chunk_size, const PackedFloat64Array& weights, Ref<ChunkWFCIO> io, int max_attempts, int seed);

	ChunkWFCEngine2D(const wfc::Vec3u& chunk_size, const wfc::TileWeights& weights, Ref<ChunkWFCIO> io, int max_attempts, int seed);
	ChunkWFCEngine2D();
	~ChunkWFCEngine2D();

	bool is_valid() const;
	Vector2i get_chunk_size() const;

	void generate_range(const Vector2i& from, const Vector2i& to);
	PackedInt32Array get_chunk(const Vector2i& coords);

};

}

// vim: ts=4 sts=4 sw=4 et

