#import <Foundation/Foundation.h>

#import <GKOSC.h>

#include <iostream>

int
main(int argc,char ** argv)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    struct GKOSCMapItem items[] = {
        @"hello",@"i",@selector(hello:),
        0,0,0
    };
    
    GKOSCUDPTransporter * d = [[GKOSCUDPTransporter alloc] initWithHostname:@"localhost" andPort:9200];
        
    GKOSCClient * client = [[GKOSCClient alloc] initWithMapping:items];
    [client addPacketTransporter:d];
    
    [client hello:42];
    
    [pool release];
    
    return 0;
}