//
//  GKOSC.h

#ifndef GKOSC_GKOSC_h
#define GKOSC_GKOSC_h

#import <Foundation/Foundation.h>

struct GKOSCMapItem {
    NSString * path, * format;
    SEL selector;
};

@protocol GKOSCPacketDispatcher
- (void) dispatchPacket:(NSData *)data;
@end

@interface GKOSCClient : NSProxy
- (GKOSCClient *) initWithMapping:(struct GKOSCMapItem *)items;
- (void) addPacketDispatcher:(id<GKOSCPacketDispatcher>)dispatcher;
- (void) removePacketDispatcher:(id<GKOSCPacketDispatcher>)dispatcher;
@end

@interface GKOSCUDPDispatcher : NSObject< GKOSCPacketDispatcher >

- (GKOSCUDPDispatcher *)initWithHostname:(NSString *)hostname andPort:(int)port;

- (void)dispatchPacket:(NSData *)data;
@end

#endif