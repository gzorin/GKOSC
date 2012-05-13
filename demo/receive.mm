#import <Foundation/Foundation.h>

#import <GKOSC.h>
#import "Thing.h"

#include <iostream>

#include <ip/PacketListener.h>
#include <ip/UdpSocket.h>

int
main(int argc,char ** argv)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
        
    Thing * thing = [[Thing alloc] init];
    
    GKOSCServer * server = [[GKOSCServer alloc] init];
    [server addObject:thing withMapping:Thing_mapping];
    
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