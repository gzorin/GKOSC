#import "GKOSC.h"

#include <memory>

#include <ip/UdpSocket.h>

@implementation GKOSCUDPDispatcher
std::unique_ptr< UdpTransmitSocket > m_socket;

- (GKOSCUDPDispatcher *)initWithHostname:(NSString *)hostname andPort:(int)port
{
    m_socket.reset(new UdpTransmitSocket(IpEndpointName([hostname UTF8String],port)));
    return self;
}

- (void)dispatchPacket:(NSData *)data
{
    if(m_socket) {
        m_socket -> Send((const char *)[data bytes],(int)[data length]);
    }
}

@end