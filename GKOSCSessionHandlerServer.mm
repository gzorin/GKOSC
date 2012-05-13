// GKOSC - OSC remote procedure calling over GameKit
// Copyright (c) 2012, Alexander Betts (alex.betts@gmail.com)
//
// GKOSCSessionHandlerServer.mm

#import "GKOSC.h"

#include <iostream>

@implementation GKOSCSessionHandlerServer

- (void) receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context
{
    [self dispatchPacket:data];
}

@end