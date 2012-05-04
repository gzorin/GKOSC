#ifndef GKOSC_details_H
#define GKOSC_details_H

#include <string>
#include <type_traits>
#include <memory>
#include <stdint.h>
#include <iostream>
#include <assert.h>

#import <objc/runtime.h>

#include <osc/OscTypes.h>

namespace {
    
    template< size_t Align >
    size_t aligned_size(const size_t value)
    {
        const size_t value_mod_align = value & (Align - 1);
        return (value_mod_align != 0) ? (value + Align - value_mod_align) : value;
    }
    
    template< typename T, size_t Align >
    size_t aligned_sizeof()
    {
        return aligned_size< Align >(sizeof(T));
    }

struct path_format {
    NSString * path, * format;
    
    path_format()
    : path(0), format(0) {
    }
    
    path_format(NSString * _path,NSString * _format)
    : path(_path), format(_format) {
        if(path) [path retain];
        if(format) [format retain];
    }
        
    path_format(const path_format & rhs)
    : path(rhs.path), format(rhs.format) {
        if(path != 0) [path retain];
        if(format != 0) [format retain];
    }
    
    ~path_format() {
        if(path != 0) [path release];
        if(format != 0) [format release];
    }
};
    
}

#endif
