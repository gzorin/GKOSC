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
    
    template< typename T >
    struct TNSsmartPointer {
    protected:
        
        T * m_ptr;
        
        inline
        static void retain(T * ptr) {
            if(ptr) [ptr retain];
        }
        
        inline
        static void release(T * ptr) {
            if(ptr) [ptr release];
        }
        
    public:
        
        TNSsmartPointer(T * ptr = 0) : m_ptr(ptr) {
            retain(m_ptr);
        }
        
        TNSsmartPointer(const TNSsmartPointer & rhs) : m_ptr(rhs.m_ptr) {
            retain(m_ptr);
        }
        
        ~TNSsmartPointer() {
            release(m_ptr);
        }
        
        inline
        TNSsmartPointer & operator=(const TNSsmartPointer & rhs) {
            T * ptr = m_ptr;
            m_ptr = rhs.m_ptr;
            retain(m_ptr);
            release(ptr);
            return *this;
        }
        
        inline
        bool operator ==(const TNSsmartPointer & rhs) const {
            return m_ptr == rhs.m_ptr;
        }
        
        inline
        bool operator !=(const TNSsmartPointer & rhs) const {
            return m_ptr != rhs.m_ptr;
        }
        
        inline
        bool operator <(const TNSsmartPointer & rhs) const {
            return m_ptr < rhs.m_ptr;
        }
        
        inline
        bool operator ==(const T * rhs) const {
            return m_ptr == rhs;
        }
        
        inline
        bool operator !=(const T * rhs) const {
            return m_ptr != rhs;
        }
        
        inline
        bool operator <(const T * rhs) const {
            return m_ptr < rhs;
        }
        
        inline
        T * it() const {
            return m_ptr;
        }
        
        inline
        operator bool() const {
            return m_ptr != 0;
        }
        
        template< typename O >
        inline
        operator TNSsmartPointer< O >() const {
            return TNSsmartPointer< O >(m_ptr);
        }
    };
    
    struct path_format {
        TNSsmartPointer< NSString > path, format;
        
        path_format() {
        }
        
        path_format(NSString * _path,NSString * _format)
        : path(_path), format(_format) {
        }
    };    
}

#endif
