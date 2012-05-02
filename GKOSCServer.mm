#import "GKOSC.h"
#include "GKOSC_details.h"

#include <algorithm>
#include <map>
#include <set>
#include <stack>
#include <tuple>
#include <stdint.h>

#include <osc/OscReceivedElements.h>

namespace {
    struct less_path_format {
        bool operator()(const path_format & lhs,const path_format & rhs) const {
            return
                std::lexicographical_compare([lhs.path UTF8String],
                                             [lhs.path UTF8String] + [lhs.path length],
                                             [rhs.path UTF8String],
                                             [rhs.path UTF8String] + [rhs.path length]) &&
                std::lexicographical_compare([lhs.format UTF8String],
                                             [lhs.format UTF8String] + [lhs.format length],
                                             [rhs.format UTF8String],
                                             [rhs.format UTF8String] + [rhs.format length]);
        }
    };
}

@interface GKOSCServer (hidden)
- (void) dispatchMessage:(const osc::ReceivedMessage &)message;
@end

@implementation GKOSCServer
typedef std::tuple< SEL, signature_size, std::set< NSObject * > > selector_signature_objects;

std::map<
        path_format, 
        selector_signature_objects,
        less_path_format > m_mapping;

- (void) addObject:(NSObject *)object withMapping:(struct GKOSCMapItem *)items
{
    for(struct GKOSCMapItem * item = items;item -> selector != 0;++item) {
        auto tmp = m_mapping.insert(std::make_pair(path_format(item -> path,item -> format),std::make_tuple(item -> selector,signature_size(),std::set< NSObject * >())));
        selector_signature_objects & sso = tmp.first -> second;
        
        if(tmp.second) {
            std::get< 1 >(sso) = signature_size(item -> format);
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

- (void) dispatchMessage:(const osc::ReceivedMessage &)message
{    
    NSString * path = [[NSString alloc] initWithBytesNoCopy:(void *)message.AddressPattern() length:strlen(message.AddressPattern()) encoding:NSUTF8StringEncoding freeWhenDone:NO];
    NSString * format = [[NSString alloc] initWithBytesNoCopy:(void *)message.TypeTags() length:message.ArgumentCount() encoding:NSUTF8StringEncoding freeWhenDone:NO];
    
    auto it = m_mapping.find(path_format(path,format));
    if(it != m_mapping.end()) {
        selector_signature_objects & sso = it -> second;
        
        // Build the invocation:
        NSMethodSignature * signature = std::get< 1 >(sso).signature;
        NSInvocation * invocation = [[NSInvocation invocationWithMethodSignature:signature] retain];
        [invocation setSelector:std::get< 0 >(sso)];
        
        NSString * format = it -> first.format;
        const size_t ntypes = [format length];
        
        osc::ReceivedMessage::const_iterator arg = message.ArgumentsBegin();
        for(size_t i = 0,j = 2;i < ntypes;++arg,++i,++j) {
            const osc::TypeTagValues type = (osc::TypeTagValues)[format characterAtIndex:i];
            
            if(type == osc::INT32_TYPE_TAG) {
                int32_t value = arg -> AsInt32();
                [invocation setArgument:&value atIndex:j];
            }
        }
        
        // Invoke this method on the objects:
        const std::set< NSObject * > & objects = std::get< 2 >(sso);
        for(NSObject * object : objects) {
            [invocation invokeWithTarget:object];
        }
        
        [invocation release];
    }
    
    [path release];
    [format release];
}

- (void) dispatchPacket:(NSData *)data
{    
    osc::ReceivedPacket packet((const char *)[data bytes],(int32_t)[data length]);
    
    if(packet.IsMessage()) {
        [self dispatchMessage:osc::ReceivedMessage(packet)];
    }
    else if(packet.IsBundle()) {
        std::stack< osc::ReceivedBundle > bundles;
        bundles.push(osc::ReceivedBundle(packet));
        
        while(!bundles.empty()) {
            osc::ReceivedBundle bundle = bundles.top();
            bundles.pop();
            
            for(auto it = bundle.ElementsBegin(),it_end = bundle.ElementsEnd();it != it_end;++it) {
                if(it -> IsBundle()) {
                    bundles.push(osc::ReceivedBundle(*it));
                }
                else {
                    [self dispatchMessage:osc::ReceivedMessage(*it)];
                }
            }
        }
    }
}

@end