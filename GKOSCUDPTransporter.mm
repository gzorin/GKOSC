// GKOSC - OSC remote procedure calling over GameKit
// Copyright (c) 2012, Alexander Betts (alex.betts@gmail.com)
//
// GKOSCUDPTransporter.mm

#import "GKOSC.h"

#include <memory>

@implementation GKOSCUDPTransporter
- (void)transportPacket:(NSData *)data
{
    [self sendData:data];
}

@end