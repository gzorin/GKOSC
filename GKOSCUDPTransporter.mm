#import "GKOSC.h"

#include <memory>

#include <ip/UdpSocket.h>

@implementation GKOSCUDPTransporter
std::unique_ptr< UdpTransmitSocket > m_socket;

- (GKOSCUDPTransporter *)initWithHostname:(NSString *)hostname andPort:(int)port
{
    m_socket.reset(new UdpTransmitSocket(IpEndpointName([hostname UTF8String],port)));
    return self;
}

- (void)transportPacket:(NSData *)data
{
    if(m_socket) {
        m_socket -> Send((const char *)[data bytes],(int)[data length]);
    }
}

@end