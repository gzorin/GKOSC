#import <Foundation/Foundation.h>

#import <GKOSC.h>
#import "UDPEcho.h"
#import "Thing.h"

#include <iostream>

@interface Receiver : NSObject< UDPEchoDelegate >
@end
    
@implementation Receiver
@end

int
main(int argc,char ** argv)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
        
    Thing * thing = [[Thing alloc] init];
    
    GKOSCUDPServer * server = [[GKOSCUDPServer alloc] init];
    [server addObject:thing withMapping:Thing_mapping];
    
    UDPEcho * r = [[UDPEcho alloc] init];
    r.delegate = server;
    [r startServerOnPort:9200];
    
    [[NSRunLoop currentRunLoop] run];
    
    [pool release];
    
    return 0;
}