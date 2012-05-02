#import <Foundation/Foundation.h>

#import <GKOSC.h>

#include <iostream>

@interface RealClient : NSObject
- (void) hello:(int32_t)x;
@end

@implementation RealClient
- (void) hello:(int32_t)x
{
    std::cerr << "real_hello: " << x << std::endl;
}
@end

int
main(int argc,char ** argv)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    struct GKOSCMapItem items[] = {
        @"hello",@"i",@selector(hello:),
        0,0,0
    };
    
    GKOSCUDPDispatcher * d = [[GKOSCUDPDispatcher alloc] initWithHostname:@"localhost" andPort:9200];
        
    GKOSCClient * client = [[GKOSCClient alloc] initWithMapping:items];
    [client addPacketDispatcher:d];
    
    [client hello:42];
    
    [pool release];
    
    return 0;
}