#pragma once

#include <vector>

/*
 * A std::vector wrapper to make a contiguous array behave like a 2 dimensional one.
 */ 
template<typename T>
class Array2D {
private:
    const std::size_t width, height;
    std::vector<T> data;

public:
    Array2D(std::size_t p_width, std::size_t p_heigth)
    : width(p_heigth), height(p_heigth), data(p_width * p_heigth)
    {}    

    Array2D(std::size_t p_width, std::size_t p_heigth, const T& init_value)
    : width(p_heigth), height(p_heigth), data(p_width * p_heigth, init_value)
    {}    

    T& elem(std::size_t x, std::size_t y) {
        return data[y * width + x];
    }

    const T& get(std::size_t x, std::size_t y) const {
        return data[y * width + x];
    }

    template<typename U>
    void set(std::size_t x, std::size_t y, U&& value) {
        data[y * width + x] = std::forward<U>(value);
    }

    auto begin() {
        return data.begin();
    }

    auto cbegin() const {
        return data.cbegin();
    }

    auto end() {
        return data.end();
    }

    auto cend() const{
        return data.cend();
    }

    std::size_t get_width() const {
        return width;
    }

    std::size_t get_height() const {
        return height;
    }
};

