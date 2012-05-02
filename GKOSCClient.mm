//
//  GKOSCClient.mm

#import "GKOSC.h"
#include "GKOSC_details.h"

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
}

@implementation GKOSCClient

std::unordered_map< SEL, std::pair< path_format, signature_size >, hash_SEL, equal_to_SEL > m_mapping;
std::stack< std::pair< path_format, size_t > > m_invocationStack;
std::set< id<GKOSCPacketDispatcher > > m_dispatchers;

- (GKOSCClient *)initWithMapping:(struct GKOSCMapItem *)items
{
    for(struct GKOSCMapItem * item = items;item -> selector != 0;++item) {
        auto tmp = m_mapping.insert(std::make_pair(item -> selector,std::make_pair(path_format(),signature_size())));
        if(tmp.second) {
            tmp.first -> second.first = path_format(item -> path,item -> format);
            tmp.first -> second.second = signature_size(item -> format);
        }
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
        m_invocationStack.push(std::make_pair(it -> second.first,it -> second.second.size));
        return it -> second.second.signature;
    }
    else {
        return [super methodSignatureForSelector:sel];
    }
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    assert(!m_invocationStack.empty());
    
    const path_format & ps = m_invocationStack.top().first;
    NSString * format = ps.format;
    const size_t ntypes = [format length];
    
    const size_t fixed_size = m_invocationStack.top().second;
    
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
        fixed_size +
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