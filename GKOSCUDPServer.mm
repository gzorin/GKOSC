#import "GKOSC.h"

@implementation GKOSCUDPServer

- (void)echo:(UDPEcho *)echo didReceiveData:(NSData *)data fromAddress:(NSData *)addr
{
    [self dispatchPacket:data];
}

@end