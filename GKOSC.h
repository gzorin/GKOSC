//
//  GKOSC.h

#ifndef GKOSC_h
#define GKOSC_h

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

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

@interface GKOSCSessionTransporter : NSObject< GKOSCPacketTransporter >
- (GKOSCSessionTransporter *)init;
- (GKOSCSessionTransporter *)initWithSession:(GKSession *)session;
- (GKOSCSessionTransporter *)initWithSession:(GKSession *)session andPeer:(NSString *)peer;
- (GKOSCSessionTransporter *)initWithSession:(GKSession *)session andPeers:(NSArray *)peers;

@property(retain) GKSession * session;
@property BOOL sendToAllSessionPeers;
@property GKSendDataMode sendMode;

- (void)addPeer:(NSString *)peer;
- (void)removePeer:(NSString *)peer;
- (void)setAllPeers:(NSArray *)peers;
- (void)removeAllPeers;

- (void)transportPacket:(NSData *)data;
@end

@interface GKOSCSessionHandlerServer : GKOSCServer< GKSessionDelegate >
@end

#endif