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
    
    struct signature_size {
        NSMethodSignature * signature;
        size_t size;
        
        signature_size()
        : signature(0), size(0) {
        }
        
        signature_size(const signature_size & rhs)
        : signature(rhs.signature), size(rhs.size) {
            if(signature) [signature retain];
        }
        
        signature_size(NSString * format)
        : signature(0), size(0) {
            const size_t ntypes = [format length];
            
            std::string types;
            
            // Types for implicit Objective C method arguments:
            //
            // Return value (void):
            types += @encode(void);
            
            // Object:
            types += @encode(id);
            
            // Selector:
            types += @encode(SEL);
            
            for(size_t i = 0;i < ntypes;++i) {
                switch([format characterAtIndex:i]) {
                    case osc::TRUE_TYPE_TAG:
                    case osc::FALSE_TYPE_TAG:
                        types += std::string(@encode(BOOL));
                        break;
                    case osc::NIL_TYPE_TAG:
                        types += std::string(@encode(const void *));
                        break;
                    case osc::INT32_TYPE_TAG:
                        types += std::string(@encode(int32_t));
                        size += aligned_sizeof< int32_t, 4 >();
                        break;
                    case osc::FLOAT_TYPE_TAG:
                        types += std::string(@encode(float));
                        size += aligned_sizeof< float, 4 >();
                        break;
                    case osc::CHAR_TYPE_TAG:
                        types += std::string(@encode(char));
                        size += aligned_sizeof< char, 4 >();
                        break;
                    case osc::RGBA_COLOR_TYPE_TAG:
                    case osc::MIDI_MESSAGE_TYPE_TAG:
                        types += std::string(@encode(uint32_t));
                        size += aligned_sizeof< uint32_t, 4 >();
                        break;
                    case osc::INT64_TYPE_TAG:
                        types += std::string(@encode(int64_t));
                        size += aligned_sizeof< int64_t, 4 >();
                        break;
                    case osc::TIME_TAG_TYPE_TAG:
                        types += std::string(@encode(uint64_t));
                        size += aligned_sizeof< uint64_t, 4 >();
                        break;
                    case osc::DOUBLE_TYPE_TAG:
                        types += std::string(@encode(double));
                        size += aligned_sizeof< double, 4 >();
                        break;
                    case osc::STRING_TYPE_TAG:
                    case osc::SYMBOL_TYPE_TAG:
                    case osc::BLOB_TYPE_TAG:
                        types += std::string(@encode(id));
                        break;
                    default:
                        types += '?';
                        break;
                }
            }
            
            std::cerr << "want types: " << types << std::endl;
            
            signature = [[NSMethodSignature signatureWithObjCTypes:types.c_str()] retain];
        }
        
        ~signature_size() {
            if(signature) [signature release];
        }
    };

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
