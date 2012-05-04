#import <Foundation/Foundation.h>

#import <GKOSC.h>

#include <iostream>

#include <ip/PacketListener.h>
#include <ip/UdpSocket.h>

struct GKOSCMapItem RealClient_mapping[] = {
    @"hello",@"if",@selector(hello:value:),
    0,0,0
};

@interface RealClient : NSObject
- (void) hello:(int32_t)x value:(float)t;
@end

@implementation RealClient
- (void) hello:(int32_t)x value:(float)t;
{
    std::cerr << "real_hello: " << x << " " << t << std::endl;
}
@end

int
main(int argc,char ** argv)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
        
    RealClient * real_client = [[RealClient alloc] init];
    
    GKOSCServer * server = [[GKOSCServer alloc] init];
    [server addObject:real_client withMapping:RealClient_mapping];
    
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