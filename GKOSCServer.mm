#import "GKOSC.h"
#include "GKOSC_details.h"

#include <algorithm>
#include <map>
#include <set>
#include <stack>
#include <tuple>
#include <stdint.h>
#include <string.h>

namespace {
    struct less_path_format {
        bool operator()(const path_format & lhs,const path_format & rhs) const {
            const NSComparisonResult less_path = [lhs.path.it() compare:rhs.path.it()];
            return (less_path == NSOrderedAscending) || (less_path == NSOrderedSame && [lhs.format.it() compare:rhs.format.it()] == NSOrderedAscending);
        }
    };
}

@implementation GKOSCServer
typedef std::tuple< SEL, TNSsmartPointer<NSMethodSignature>, std::set< TNSsmartPointer<NSObject> > > selector_signature_objects;

std::map<
        path_format, 
        selector_signature_objects,
        less_path_format > m_mapping;

+ (BOOL) decodePacket:(NSData *)packet toInvocations:(NSMutableArray *)invocations toPaths:(NSMutableArray *)paths toFormats:(NSMutableArray *)formats
{
    size_t len = [packet length];
    const uint8_t * bytes = (const uint8_t *)[packet bytes];
    
    std::stack< std::pair< const uint8_t *, size_t > > s;
    s.push(std::make_pair(bytes,len));
    
    while(!s.empty()) {
        const uint8_t * pbytes = s.top().first;
        size_t len = s.top().second;
        s.pop();
        
        // It's a bundle:
        if(*pbytes == '#') {
            // Bundle header:
            if((len < 8) || (strcmp((const char *)pbytes,"#bundle") != 0)) return NO;
            pbytes += 8;
            len -= 8;
            
            // Timetag:
            if(len < 8) return NO;
            pbytes += 8;
            len -= 8;
            
            // Bundle elements:            
            while(len > 0) {
                // The size of the element:
                if(len < sizeof(int32_t)) return NO;
                const int32_t element_len = CFSwapInt32BigToHost(*(int32_t *)pbytes);
                pbytes += sizeof(int32_t);
                len -= sizeof(int32_t);
                
                // Its data:
                if(len < element_len) return NO;
                s.push(std::make_pair(pbytes,element_len));
                pbytes += element_len;
                len -= element_len;
            }
        }
        // It's a message:
        else {            
            // Path:
            if(len == 0) return NO;
            
            size_t path_len = 0;
            for(const uint8_t * p = pbytes;(*p != 0) && (path_len < len);++p) {
                ++path_len;
            }
            if(pbytes[path_len] != 0) return NO;
            
            const char * ppath = (const char *)pbytes;
            pbytes += aligned_size< 4 >(path_len + 1);
            len -= aligned_size< 4 >(path_len + 1);
            
            // Type tags:
            if(len == 0) return NO;
            
            size_t type_tags_len = 0;
            for(const uint8_t * p = pbytes;(*p != 0) && (type_tags_len < len);++p) {
                ++type_tags_len;
            }
            if(pbytes[type_tags_len] != 0) return NO;
            
            const char * ptype_tags = (const char *)pbytes;
            pbytes += aligned_size< 4 >(type_tags_len + 1);
            len -= aligned_size< 4 >(type_tags_len + 1);
            
            if(*ptype_tags != ',') return NO;
            ++ptype_tags;
                        
            // Construct the message signature:
            NSMethodSignature * signature = [GKOSCClient methodSignatureWithFormat:[[NSString alloc] initWithBytesNoCopy:(void *)ptype_tags length:type_tags_len - 1 encoding:NSUTF8StringEncoding freeWhenDone:NO]];
            
            // Construct the invocation:
            NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:signature];
            
            size_t i = 1;
            const char * pptype_tags = ptype_tags;
            for(size_t j = 2;i < type_tags_len && len > 0;++i,++pptype_tags,++j) {
                if(*pptype_tags == 'i') {
                    if(len < sizeof(int32_t)) break;
                    
                    int32_t value = CFSwapInt32BigToHost(*(uint32_t *)pbytes);
                    [invocation setArgument:&value atIndex:j];
                    
                    pbytes += sizeof(int32_t);
                    len -= sizeof(int32_t);
                }
                else if(*pptype_tags == 'f') {
                    if(len < sizeof(uint32_t)) break;
                    
                    CFSwappedFloat32 tmp;
                    tmp.v = *(uint32_t *)pbytes;
                    
                    float value = CFConvertFloat32SwappedToHost(tmp);
                    [invocation setArgument:&value atIndex:j];
                    
                    pbytes += sizeof(uint32_t);
                    len -= sizeof(uint32_t);
                }
                else if(*pptype_tags == 's') {
                    size_t slen = 0;
                    const uint8_t * ppbytes = pbytes;
                    while(*ppbytes != 0 && slen < len) {
                        ++ppbytes;
                        ++slen;
                    }
                    if(*ppbytes != 0) break;
                    
                    NSString * value = [NSString stringWithUTF8String:(const char *)pbytes];
                    [invocation setArgument:&value atIndex:j];
                    pbytes += aligned_size< 4 >(slen + 1);
                    len -= aligned_size< 4 >(slen + 1);
                }
                else if(*pptype_tags == 'b') {
                    if(len < sizeof(int32_t)) break;
                    
                    int32_t blen = CFSwapInt32BigToHost(*(uint32_t *)pbytes);
                    
                    if(len < (blen + sizeof(int32_t))) break;
                    
                    NSData * value = [NSData dataWithBytes:pbytes + sizeof(int32_t) length:blen];
                    [invocation setArgument:&value atIndex:j];
                    pbytes += aligned_size< 4 >(blen + sizeof(int32_t));
                    len -= aligned_size< 4 >(blen + sizeof(int32_t));
                }
            }
            
            [invocations addObject:invocation];
            [paths addObject:[NSString stringWithUTF8String:ppath]];
            [formats addObject:[NSString stringWithUTF8String:ptype_tags]];
        }
    }
    
    return YES;
}

- (void) addObject:(NSObject *)object withMapping:(struct GKOSCMapItem *)items
{
    for(struct GKOSCMapItem * item = items;item -> path != 0;++item) {        
        auto tmp = m_mapping.insert(std::make_pair(path_format(item -> path,item -> format),std::make_tuple(item -> selector,(NSMethodSignature *)0,std::set< TNSsmartPointer<NSObject> >())));
        selector_signature_objects & sso = tmp.first -> second;
        
        if(tmp.second) {
            std::get< 1 >(sso) = [GKOSCClient methodSignatureWithFormat:item -> format];
        }
        std::get< 2 >(sso).insert(object);
    }
}

- (void) removeObject:(NSObject *)object
{
    for(auto tmp : m_mapping) {
        std::get< 2 >(tmp.second).erase(object);
    }
}

- (void) dispatchPacket:(NSData *)data
{    
    NSMutableArray * invocations = [[[NSMutableArray alloc] init] retain], * paths = [[[NSMutableArray alloc] init] retain], * formats = [[[NSMutableArray alloc] init] retain];
    BOOL status = [GKOSCServer decodePacket:data toInvocations:invocations toPaths:paths toFormats:formats];
    
    if(status) {
        const size_t n = [invocations count];
        for(size_t i = 0;i < n;++i) {
            NSInvocation * invocation = [invocations objectAtIndex:i];
            NSString * path = [paths objectAtIndex:i];
            NSString * format = [formats objectAtIndex:i];
            
            auto it = m_mapping.find(path_format(path,format));
            if(it != m_mapping.end()) {
                selector_signature_objects & sso = it -> second;
                
                [invocation setSelector:std::get< 0 >(sso)];
                
                for(TNSsmartPointer<NSObject> object : std::get< 2 >(sso)) {
                    [invocation invokeWithTarget:object.it()];
                }
            }
        }
    }
    
    [invocations release];
    [paths release];
    [formats release];
}

@end