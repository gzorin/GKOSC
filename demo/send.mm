#import <Foundation/Foundation.h>

#import <GKOSC.h>
#import "Thing.h"

#include <iostream>
#include <math.h>

int
main(int argc,char ** argv)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    GKOSCUDPTransporter * d = [[GKOSCUDPTransporter alloc] initWithHostname:@"localhost" andPort:9200];
        
    GKOSCClient< Thing > * client = (GKOSCClient< Thing > *)[[GKOSCClient alloc] initWithMapping:Thing_mapping];
    [client addPacketTransporter:d];
    
    [client hello:(int32_t)42 value:(float)M_PI * 2.0f];
    [client goodbye:(int32_t)42 value:(float)M_E];
    
    [pool release];
    
    return 0;
}