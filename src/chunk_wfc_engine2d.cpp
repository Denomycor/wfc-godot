#include "chunk_wfc_engine2d.hpp"
#include "array3d.hpp"
#include "chunk_wfc.hpp"
#include "godot_cpp/core/class_db.hpp"
#include "godot_cpp/core/memory.hpp"
#include "godot_cpp/core/property_info.hpp"
#include "godot_cpp/variant/packed_int32_array.hpp"
#include "godot_cpp/variant/variant.hpp"
#include "godot_cpp/variant/vector2i.hpp"
#include "utils.hpp"
#include <memory>
#include <optional>

using namespace godot;



// ChunkWFCIO

ChunkWFCIO::ChunkWFCIO()
:handler(std::make_shared<wfc::NullChunkWFCIO>())
{}

ChunkWFCIO::ChunkWFCIO(const std::shared_ptr<wfc::ChunkWFCIO>& p_handler)
:handler(p_handler)
{}



// DiskChunkWFCIO

void DiskChunkWFCIO::_bind_methods(){
    ClassDB::bind_method(D_METHOD("flush_index"), &DiskChunkWFCIO::flush_index);
    ClassDB::bind_static_method("DiskChunkWFCIO", D_METHOD("open", "index", "chunks", "size"), &DiskChunkWFCIO::open);
}


Ref<DiskChunkWFCIO> DiskChunkWFCIO::open(const String& index, const String& chunks, const Vector2i& size){
    std::string i = index.utf8().get_data();
    std::string c = chunks.utf8().get_data();
    wfc::Vec3u s = {static_cast<unsigned int>(size.x), static_cast<unsigned int>(size.y), 1};
    return memnew(DiskChunkWFCIO(i,c,s));
}


DiskChunkWFCIO::DiskChunkWFCIO(const std::filesystem::path& index_path, const std::filesystem::path& chunks_path, const wfc::Vec3u& chunk_size)
:ChunkWFCIO(std::make_shared<wfc::DiskChunkWFCIO>(index_path, chunks_path, chunk_size)), valid(true)
{}


DiskChunkWFCIO::DiskChunkWFCIO()
:ChunkWFCIO(), valid(false)
{}


DiskChunkWFCIO::~DiskChunkWFCIO(){}


void DiskChunkWFCIO::flush_index(){
    auto ptr = dynamic_cast<wfc::DiskChunkWFCIO*>(handler.get());
    if(ptr) ptr->flush_index();
}



//CustomChunkWFCIO

void CustomChunkWFCIO::_bind_methods(){
    ClassDB::bind_method(D_METHOD("reader", "coords"), &CustomChunkWFCIO::reader);
    ClassDB::bind_method(D_METHOD("writer", "coords", "data"), &CustomChunkWFCIO::writer);
    ClassDB::bind_method(D_METHOD("get_chunk_size"), &CustomChunkWFCIO::get_chunk_size);
    ClassDB::bind_method(D_METHOD("set_chunk_size", "chunk_size"), &CustomChunkWFCIO::set_chunk_size);

	ADD_PROPERTY(PropertyInfo(Variant::VECTOR2I, "chunk_size"), "set_chunk_size", "get_chunk_size");

}


PackedInt32Array CustomChunkWFCIO::reader(const Vector2i& coords){return {};}
void CustomChunkWFCIO::writer(const Vector2i& coords, const PackedInt32Array& data){}


CustomChunkWFCIO::CustomChunkWFCIO()
:ChunkWFCIO(std::make_shared<_impWFCIO>(this)), m_chunk_size(1,1,1)
{}


void CustomChunkWFCIO::set_chunk_size(const Vector2i& size){
    m_chunk_size = {static_cast<unsigned int>(size.x), static_cast<unsigned int>(size.y), 1};
}


Vector2i CustomChunkWFCIO::get_chunk_size(){
    return Vector2i(m_chunk_size.x, m_chunk_size.y);
}


std::optional<wfc::Array3D<unsigned int>> CustomChunkWFCIO::_impWFCIO::reader(const wfc::Vec3i& coords){
    auto result = ptr->reader(Vector2i(coords.x, coords.y));
    if(result.is_empty()){
        return {};
    }else{
        auto[x,y,z] = ptr->m_chunk_size;
        wfc::Array3D<unsigned int> buffer(x,y,z);
        for(int i=0; i<result.size(); i++){
            buffer.get_linear(i) = result[i];
        }
        return buffer;
    }
};


void CustomChunkWFCIO::_impWFCIO::writer(const wfc::Vec3i& coords, const wfc::Array3D<unsigned int>& result){
    PackedInt32Array buffer;
    buffer.resize(result.size());
    for(int i=0; i< result.size(); i++){
        buffer[i] = result.get_linear(i);
    }
    ptr->writer(Vector2i(coords.x, coords.y), buffer);
}



// ChunkWFCEngine2D

void ChunkWFCEngine2D::_bind_methods(){
    ClassDB::bind_static_method("ChunkWFCEngine2D", D_METHOD("make_generator", "chunk_size", "weights", "io", "max_attempts", "seed"), &ChunkWFCEngine2D::make_generator);
    ClassDB::bind_method(D_METHOD("is_valid"), &ChunkWFCEngine2D::is_valid);
    ClassDB::bind_method(D_METHOD("get_chunk_size"), &ChunkWFCEngine2D::get_chunk_size);
    ClassDB::bind_method(D_METHOD("generate_range", "from", "to"), &ChunkWFCEngine2D::generate_range);
    ClassDB::bind_method(D_METHOD("get_chunk", "coords"), &ChunkWFCEngine2D::get_chunk);

    ADD_SIGNAL(MethodInfo("successful_chunk", PropertyInfo(Variant::VECTOR2I, "coords"), PropertyInfo(Variant::PACKED_INT32_ARRAY, "data")));
    ADD_SIGNAL(MethodInfo("failed_chunk", PropertyInfo(Variant::VECTOR2I, "coords")));

	ADD_PROPERTY(PropertyInfo(Variant::VECTOR2I, "chunk_size"), "", "get_chunk_size");
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "valid"), "", "is_valid");
}


Ref<ChunkWFCEngine2D> ChunkWFCEngine2D::make_generator(const Vector2i& chunk_size, const PackedFloat64Array& weights,Ref<ChunkWFCIO> io, int max_attempts, int seed){
    wfc::TileWeights convert(weights.size());
    for(const auto& e : weights){
        convert.emplace_back(static_cast<double>(e));
    }
	wfc::Vec3u size = {static_cast<unsigned int>(chunk_size.x), static_cast<unsigned int>(chunk_size.y), 1};

    return memnew(ChunkWFCEngine2D(size, convert, io, max_attempts, seed));
}


ChunkWFCEngine2D::ChunkWFCEngine2D(const wfc::Vec3u& chunk_size, const wfc::TileWeights& weights,Ref<ChunkWFCIO> io, int max_attempts, int seed)
: wfc_generator(chunk_size, weights, io->handler, max_attempts, seed), m_io(io), valid(true)
{
	_setup();
}


ChunkWFCEngine2D::ChunkWFCEngine2D()
: wfc_generator({1,1,1}, {1}, std::make_shared<wfc::NullChunkWFCIO>(), 1), valid(false)
{
	_setup();
}


void ChunkWFCEngine2D::_setup(){
    wfc_generator.successful_chunk.connect([this](const wfc::Vec3i& coords, const wfc::Array3D<unsigned int>& data){
        PackedInt32Array buffer;
        buffer.resize(data.size());
        for(int i=0; i< data.size(); i++){
            buffer[i] = data.get_linear(i);
        }
        emit_signal("successful_chunk", Vector2i(coords.x, coords.y), buffer);
    });
    wfc_generator.failed_chunk.connect([this](const wfc::Vec3i& coords){
        emit_signal("failed_chunk", Vector2i(coords.x, coords.y));
    });
}


bool ChunkWFCEngine2D::is_valid() const {
	return valid;
}


Vector2i ChunkWFCEngine2D::get_chunk_size() const {
	auto res = wfc_generator.get_chunk_size();
	return {static_cast<int32_t>(res.x), static_cast<int32_t>(res.y)};
}


void ChunkWFCEngine2D::generate_range(const Vector2i& from, const Vector2i& to){
	wfc::Vec3i f = {from.x, from.y, 0};
	wfc::Vec3i t = {to.x, to.y, 1};
	wfc_generator.generate_range(f, t);
}


PackedInt32Array ChunkWFCEngine2D::get_chunk(const Vector2i& coords){
	wfc::Vec3i c = {coords.x, coords.y, 0};
	auto result = wfc_generator.get_chunk(c);
	if(result.has_value()){
		PackedInt32Array buffer;
		for(auto v : result.value()){
			buffer.append(v);
		}
		return buffer;
	}else{
		return {};
	}
}


ChunkWFCEngine2D::~ChunkWFCEngine2D(){}



// vim: ts=4 sts=4 sw=4 et

