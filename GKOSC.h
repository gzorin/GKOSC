//
//  GKOSC.h

#ifndef GKOSC_GKOSC_h
#define GKOSC_GKOSC_h

#import <Foundation/Foundation.h>

struct GKOSCMapItem {
    NSString * path, * format;
    SEL selector;
};

@protocol GKOSCPacketTransporter
- (void) transportPacket:(NSData *)data;
@end

@interface GKOSCClient : NSProxy
- (GKOSCClient *) initWithMapping:(struct GKOSCMapItem *)items;
- (void) addPacketTransporter:(id<GKOSCPacketTransporter>)dispatcher;
- (void) removePacketTransporter:(id<GKOSCPacketTransporter>)dispatcher;
@end

@interface GKOSCServer : NSObject
- (void) addObject:(NSObject *)object withMapping:(struct GKOSCMapItem *)items;
- (void) removeObject:(NSObject *)object;
- (void) dispatchPacket:(NSData *)data;
@end

@interface GKOSCUDPTransporter : NSObject< GKOSCPacketTransporter >
- (GKOSCUDPTransporter *)initWithHostname:(NSString *)hostname andPort:(int)port;
- (void)transportPacket:(NSData *)data;
@end

#endif