#import "GKOSC.h"

#include <iostream>

@implementation GKOSCSessionTransporter
@synthesize session;
@synthesize sendToAllSessionPeers;
@synthesize sendMode;

NSMutableArray * m_peers;

- (GKOSCSessionTransporter *)init
{
    [super init];
    session = nil;
    m_peers = [[[NSMutableArray alloc] init] retain];
    sendToAllSessionPeers = NO;
    sendMode = GKSendDataUnreliable;
    return self;
}

- (GKOSCSessionTransporter *)initWithSession:(GKSession *)theSession
{
    [self init];
    session = theSession;
    return self;
}

- (GKOSCSessionTransporter *)initWithSession:(GKSession *)theSession andPeer:(NSString *)peer
{
    [self initWithSession:theSession];
    [m_peers addObject:peer];
    return self;
}

- (GKOSCSessionTransporter *)initWithSession:(GKSession *)theSession andPeers:(NSArray *)peers
{
    [self initWithSession:theSession];
    [m_peers addObjectsFromArray:peers];
    return self;
}

- (void)dealloc
{
    [m_peers release];
    [super dealloc];
}

- (void)addPeer:(NSString *)peer
{
    [m_peers addObject:peer];
}

- (void)removePeer:(NSString *)peer
{
    [m_peers removeObject:peer];
}

- (void)setAllPeers:(NSArray *)peers
{
    [m_peers setArray:peers];
}

- (void)removeAllPeers
{
    [m_peers removeAllObjects];
}

- (void)transportPacket:(NSData *)data
{
    if(session != nil) {
        if(sendToAllSessionPeers) {
            [session sendDataToAllPeers:data withDataMode:sendMode error:NULL];
        }
        else {
            std::cerr << "Sending " << [data length] << " to all peers" << std::endl;
        }
    }
}

@end