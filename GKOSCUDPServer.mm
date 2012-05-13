// GKOSC - OSC remote procedure calling over GameKit
// Copyright (c) 2012, Alexander Betts (alex.betts@gmail.com)
//
// GKOSCUDPServer.mm

#import "GKOSC.h"

@implementation GKOSCUDPServer

- (void)echo:(UDPEcho *)echo didReceiveData:(NSData *)data fromAddress:(NSData *)addr
{
    [self dispatchPacket:data];
}

@end