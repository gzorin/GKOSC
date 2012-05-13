#import "GKOSC.h"

#include <memory>

@implementation GKOSCUDPTransporter
- (void)transportPacket:(NSData *)data
{
    [self sendData:data];
}

@end