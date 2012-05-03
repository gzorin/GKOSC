#import "GKOSC.h"

@implementation GKOSCSessionHandlerServer

- (void) receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context
{
    [self dispatchPacket:data];
}

@end