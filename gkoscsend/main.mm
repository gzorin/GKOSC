#import <Foundation/Foundation.h>

#import <GKOSC.h>

#include <iostream>
#include <math.h>

@interface RealClient : NSObject
- (void) hello:(int32_t)x value:(float)t;
@end

int
main(int argc,char ** argv)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    struct GKOSCMapItem items[] = {
        @"hello",@"if",@selector(hello:value:),
        0,0,0
    };
    
    GKOSCUDPTransporter * d = [[GKOSCUDPTransporter alloc] initWithHostname:@"localhost" andPort:9200];
        
    RealClient * client = (RealClient *)[[GKOSCClient alloc] initWithMapping:items];
    [client addPacketTransporter:d];
    
    [client hello:(int32_t)42 value:(float)M_PI * 2.0f];
    
    [pool release];
    
    return 0;
}