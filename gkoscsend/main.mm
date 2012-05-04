#import <Foundation/Foundation.h>

#import <GKOSC.h>

#include <iostream>
#include <math.h>

struct GKOSCMapItem RealClient_mapping[] = {
    @"hello",@"if",@selector(hello:value:),
    0,0,0
};

@interface RealClient : NSObject
- (void) hello:(int32_t)x value:(float)t;
@end

int
main(int argc,char ** argv)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    GKOSCUDPTransporter * d = [[GKOSCUDPTransporter alloc] initWithHostname:@"localhost" andPort:9200];
        
    RealClient * client = (RealClient *)[[GKOSCClient alloc] initWithMapping:RealClient_mapping];
    [client addPacketTransporter:d];
    
    [client hello:(int32_t)42 value:(float)M_PI * 2.0f];
    
    [pool release];
    
    return 0;
}