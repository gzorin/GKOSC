#import <Foundation/Foundation.h>

#import <GKOSC.h>
#import "Thing.h"

#include <iostream>

#include <ip/PacketListener.h>
#include <ip/UdpSocket.h>

@interface RealThing : NSObject< Thing >
@end

@implementation RealThing
- (void) hello:(int32_t)x value:(float)t;
{
    std::cerr << "hello: " << x << " " << t << std::endl;
}

- (void) goodbye:(int32_t)x value:(float)t;
{
    std::cerr << "goodbye: " << x << " " << t << std::endl;
}
@end

int
main(int argc,char ** argv)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
        
    RealThing * real_client = [[RealThing alloc] init];
    
    GKOSCServer * server = [[GKOSCServer alloc] init];
    [server addObject:real_client withMapping:Thing_mapping];
    
    struct Listener : PacketListener {
        GKOSCServer * server;
        
        Listener(GKOSCServer * _server)
        : server(_server) {
        }
        
        void ProcessPacket(const char * data,int size,const IpEndpointName &) {
            [server dispatchPacket:[NSData dataWithBytesNoCopy:(void *)data length:size freeWhenDone:NO]];
        }
    } listener(server);
    
    UdpListeningReceiveSocket socket(IpEndpointName(IpEndpointName::ANY_ADDRESS,9200),&listener);
    socket.RunUntilSigInt();
    
    [pool release];
    
    return 0;
}