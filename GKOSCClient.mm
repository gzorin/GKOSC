//
//  GKOSCClient.mm

#import "GKOSC.h"

#include <osc/OscTypes.h>
#include <osc/OscOutboundPacketStream.h>

#import <objc/runtime.h>

#include <unordered_map>
#include <stack>
#include <set>
#include <string>
#include <type_traits>
#include <memory>
#include <stdint.h>
#include <iostream>
#include <assert.h>

namespace {
    struct hash_SEL {
        size_t operator()(SEL s) const {
            return std::hash< std::string >()(std::string(sel_getName(s)));
        }
    };
    
    struct equal_to_SEL {
        bool operator()(SEL lhs,SEL rhs) const {
            return sel_isEqual(lhs,rhs);
        }
    };
    
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
    
    struct path_signature {
        NSString * path, * format;
        NSMethodSignature * signature;
        size_t size;
        
        path_signature()
        : path(0), format(0), signature(0), size(0) {
        }
        
        path_signature(NSString * _path,NSString * _format)
            : path(_path), format(_format), signature(0), size(0) {
            assert(path != 0);
            assert(format != 0);
                
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
                
            [path retain];
            [format retain];
            signature = [[NSMethodSignature signatureWithObjCTypes:types.c_str()] retain];
        }
        
        path_signature(const path_signature & rhs)
        : path(rhs.path), format(rhs.format), signature(rhs.signature), size(rhs.size) {
            if(path != 0) [path retain];
            if(format != 0) [format retain];
            if(signature != 0) [signature retain];
        }
        
        ~path_signature() {
            if(path != 0) [path release];
            if(format != 0) [format release];
            if(signature != 0) [signature release];
        }
    };
}

@implementation GKOSCClient

std::unordered_map< SEL, path_signature, hash_SEL, equal_to_SEL > m_mapping;
std::stack< path_signature > m_invocationStack;
std::set< id<GKOSCPacketDispatcher > > m_dispatchers;

- (GKOSCClient *)initWithMapping:(struct GKOSCMapItem *)items
{
    for(struct GKOSCMapItem * item = items;item -> selector != 0;++item) {
        m_mapping.insert(std::make_pair(item -> selector,path_signature(item -> path,item -> format)));
    }
    
    return self;
}

- (void)addPacketDispatcher:(id<GKOSCPacketDispatcher>)dispatcher
{
    m_dispatchers.insert(dispatcher);
}

- (void)removePacketDispatcher:(id<GKOSCPacketDispatcher>)dispatcher
{
    m_dispatchers.erase(dispatcher);
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    auto it = m_mapping.find(sel);
    
    if(it != m_mapping.end()) {
        m_invocationStack.push(it -> second);
        return it -> second.signature;
    }
    else {
        return [super methodSignatureForSelector:sel];
    }
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    assert(!m_invocationStack.empty());
    
    const path_signature & ps = m_invocationStack.top();
    NSString * format = ps.format;
    const size_t ntypes = [format length];
    
    // Compute the size of arguments of variable sizes:
    size_t variable_size = 0;
    
    for(size_t i = 0,j = 2;i < ntypes;++i,++j) {
        const osc::TypeTagValues type = (osc::TypeTagValues)[format characterAtIndex:i];
        
        if(type == osc::STRING_TYPE_TAG ||
           type == osc::SYMBOL_TYPE_TAG) {
            NSString * value = 0;
            [invocation getArgument:&value atIndex:j];
            variable_size += [value length] + 1;
        }
        else if(type == osc::BLOB_TYPE_TAG) {
            NSData * value = 0;
            [invocation getArgument:&value atIndex:j];
            variable_size += [value length];
        }
    }
    
    const size_t size = 
        // Size of bundle header:
        (4 + 16) +
        // Size of message header:
        (4 + aligned_size< 4 >([ps.path length] + 1)) +
        // Space consumed by arguments of fixed size:
        ps.size +
        variable_size
        ;
    
    std::cerr << "Message will consume " << size << " bytes" << std::endl;
    
    NSMutableData * buffer = [[[NSMutableData alloc] initWithLength:size] retain];
    
    osc::OutboundPacketStream oscs((char *)[buffer mutableBytes],size);
    oscs << osc::BeginBundleImmediate << osc::BeginMessage([ps.path UTF8String]);
    
    for(size_t i = 0,j = 2;i < ntypes;++i,++j) {
        const osc::TypeTagValues type = (osc::TypeTagValues)[format characterAtIndex:i];
        
        if(type == osc::INT32_TYPE_TAG) {
            int32_t value = 0;
            [invocation getArgument:&value atIndex:j];
            oscs << value;
        }
    }
    
    oscs << osc::EndMessage << osc::EndBundle;
    
    for(auto dispatcher : m_dispatchers) {
        [dispatcher dispatchPacket:buffer];
    }
    
    [buffer release];
}

@end