//
//  GKOSC.h

#ifndef GKOSC_h
#define GKOSC_h

#include <Availability.h>
#import <Foundation/Foundation.h>

struct GKOSCMapItem {
    NSString * path, * format;
    SEL selector;
};

@protocol GKOSCPacketTransporter
- (void) transportPacket:(NSData *)data;
@end

@interface GKOSCClient : NSProxy
+ (NSMethodSignature *) methodSignatureWithFormat:(NSString *)format;
+ (BOOL) encodeInvocation:(NSInvocation *)invocation toPacket:(NSMutableData *)data withPath:(NSString *)path withFormat:(NSString *)format;

- (GKOSCClient *) initWithMapping:(struct GKOSCMapItem *)items;
- (void) addPacketTransporter:(id<GKOSCPacketTransporter>)dispatcher;
- (void) removePacketTransporter:(id<GKOSCPacketTransporter>)dispatcher;
@end

@interface GKOSCServer : NSObject
+ (BOOL) decodePacket:(NSData *)packet toInvocations:(NSMutableArray *)invocations toPaths:(NSMutableArray *)paths toFormats:(NSMutableArray *)formats;

- (void) addObject:(NSObject *)object withMapping:(struct GKOSCMapItem *)items;
- (void) removeObject:(NSObject *)object;
- (void) dispatchPacket:(NSData *)data;
@end

@interface GKOSCUDPTransporter : NSObject< GKOSCPacketTransporter >
- (GKOSCUDPTransporter *)initWithHostname:(NSString *)hostname andPort:(int)port;

- (void)transportPacket:(NSData *)data;
@end

#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED)
#import <GameKit/GameKit.h>

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

#endif