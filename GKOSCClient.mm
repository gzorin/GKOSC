//
//  GKOSCClient.mm

#import "GKOSC.h"
#include "GKOSC_details.h"

#include <CoreFoundation/CoreFoundation.h>

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
}

@implementation GKOSCClient

std::unordered_map< SEL, std::pair< path_format, TNSsmartPointer<NSMethodSignature> >, hash_SEL, equal_to_SEL > m_mapping;
std::set< TNSsmartPointer<NSObject<GKOSCPacketTransporter> > > m_transporters;

+ (NSMethodSignature *) methodSignatureWithFormat:(NSString *)format
{
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
            case 'T':
            case 'F':
                types += std::string(@encode(BOOL));
                break;
            case 'N':
                types += std::string(@encode(const void *));
                break;
            case 'i':
                types += std::string(@encode(int32_t));
                break;
            case 'f':
                types += std::string(@encode(float));
                break;
            case 'c':
                types += std::string(@encode(char));
                break;
            case 'r':
            case 'm':
                types += std::string(@encode(uint32_t));
                break;
            case 'h':
                types += std::string(@encode(int64_t));
                break;
            case 't':
                types += std::string(@encode(uint64_t));
                break;
            case 'd':
                types += std::string(@encode(double));
                break;
            case 's':
            case 'S':
            case 'b':
                types += std::string(@encode(id));
                break;
            default:
                types += '?';
                break;
        }
    }
    
    return [[NSMethodSignature signatureWithObjCTypes:types.c_str()] retain];
}

+ (BOOL) encodeInvocation:(NSInvocation *)invocation toPacket:(NSMutableData *)data withPath:(NSString *)path withFormat:(NSString *)format
{
    const size_t n = [format length];
    
    const uint8_t * type_tags = (const uint8_t *)[format UTF8String];
    const uint8_t * ptype_tags = type_tags;
        
    // Compute the size of the message:
    size_t args_size = 0;
    for(size_t i = 0,j = 2;i < n;++i,++j,++ptype_tags) {
        if(*ptype_tags == 'i') {
            args_size += sizeof(int32_t);
        }
        else if(*ptype_tags == 'f') {
            args_size += sizeof(float);
        }
        else if(*ptype_tags == 's') {
            NSString * value = 0;
            [invocation getArgument:&value atIndex:j];
            args_size += aligned_size< 4 >([value length] + 1);
        }
        else if(*ptype_tags == 'b') {
            NSData * value = 0;
            [invocation getArgument:&value atIndex:j];
            args_size += aligned_size< 4 >([value length] + sizeof(int32_t));
        }
    }
    
    // The size of the message header:
    const size_t message_header_size = aligned_size< 4 >([path length] + 1) + aligned_size< 4 >(n + 2);
    
    // The size of the bundle header:
    const size_t bundle_header_size = 8 + 8 + sizeof(int32_t);
    
    const size_t message_size = message_header_size + args_size;
    const size_t packet_size = bundle_header_size + message_size;
    
    NSMutableData * packet = [[NSMutableData dataWithLength:packet_size] retain];
    uint8_t * bytes = (uint8_t *)[packet mutableBytes];
        
    bytes[0] = '#';
    bytes[1] = 'b';
    bytes[2] = 'u';
    bytes[3] = 'n';
    bytes[4] = 'd';
    bytes[5] = 'l';
    bytes[6] = 'e';
    bytes[7] = 0;
    bytes += 8;
    
    *(uint64_t *)bytes = CFSwapInt64HostToBig(0);
    bytes += 8;
    
    *(int32_t *)bytes = CFSwapInt32HostToBig((uint32_t)message_size);
    bytes += sizeof(int32_t);
    
    memcpy(bytes,[path UTF8String],[path length]);
    bytes[[path length]] = 0;
    bytes += aligned_size< 4 >([path length] + 1);
    
    *bytes = ',';
    memcpy(bytes + 1,type_tags,n);
    bytes[1 + n] = 0;
    bytes += aligned_size< 4 >(n + 2);
    
    ptype_tags = type_tags;
    
    // Copy argument data:
    for(size_t i = 0,j = 2;i < n;++i,++j,++ptype_tags) {
        if(*ptype_tags == 'i') {
            int32_t value = 0;
            [invocation getArgument:&value atIndex:j];
            *(int32_t *)bytes = CFSwapInt32HostToBig(value);
            bytes += sizeof(int32_t);
        }
        else if(*ptype_tags == 'f') {
            float value = 0;
            [invocation getArgument:&value atIndex:j];
            *(uint32_t* )bytes = CFConvertFloat32HostToSwapped(value).v;
            bytes += sizeof(uint32_t);
        }
        else if(*ptype_tags == 's') {
            NSString * value = 0;
            [invocation getArgument:&value atIndex:j];
            const size_t len = [value length];
            memcpy(bytes,[value UTF8String],len);
            bytes[len] = 0;
            bytes += len + 1;
        }
        else if(*ptype_tags == 'b') {
            NSData * value = 0;
            [invocation getArgument:&value atIndex:j];
            
        }
    }
    
    [data setData:packet];
    [packet release];
    
    return YES;
}

- (GKOSCClient *)initWithMapping:(struct GKOSCMapItem *)items
{
    for(struct GKOSCMapItem * item = items;item -> path != 0;++item) {
        auto tmp = m_mapping.insert(std::make_pair(item -> selector,std::make_pair(path_format(),(NSMethodSignature *)0)));
        if(tmp.second) {
            tmp.first -> second.first = path_format(item -> path,item -> format);
            tmp.first -> second.second = [GKOSCClient methodSignatureWithFormat:item -> format];
        }
    }
    
    return self;
}

- (void)addPacketTransporter:(NSObject<GKOSCPacketTransporter> *)transporter
{
    m_transporters.insert(transporter);
}

- (void)removePacketTransporter:(NSObject <GKOSCPacketTransporter> *)transporter
{
    m_transporters.erase(transporter);
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    auto it = m_mapping.find(sel);
    
    if(it != m_mapping.end()) {
        return it -> second.second.it();
    }
    else {
        return [super methodSignatureForSelector:sel];
    }
}

- (void)forwardInvocation:(NSInvocation *)invocation
{    
    auto it = m_mapping.find([invocation selector]);
    assert(it != m_mapping.end());
    
    const path_format & ps = it -> second.first;
    NSString * path = ps.path.it();
    NSString * format = ps.format.it();
    
    NSMutableData * packet = [[NSMutableData dataWithLength:0] retain];
    
    [GKOSCClient encodeInvocation:invocation toPacket:packet withPath:path withFormat:format];
    
    for(auto transporter : m_transporters) {
        [transporter.it() transportPacket:packet];
    }
    
    [packet release];
}

@end