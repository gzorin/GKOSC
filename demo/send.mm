#import <Foundation/Foundation.h>

#import <GKOSC.h>
#import "ThingInterface.h"

#include <iostream>
#include <math.h>

@interface Sender : NSObject< UDPEchoDelegate >
@property (retain) GKOSCClient< ThingInterface > * thing;
@end

@implementation Sender
@synthesize thing;

- (void)echo:(UDPEcho *)echo didStartWithAddress:(NSData *)address
{
    [self.thing hello:@"Fred" value:(float)M_PI * 2.0f];
    
    xyz data(3,5,7);
    
    [self.thing goodbye:[NSData dataWithBytesNoCopy:&data length:sizeof(xyz) freeWhenDone:NO] value:(float)M_E];
}

- (void)echo:(UDPEcho *)echo didFailToSendData:(NSData *)data toAddress:(NSData *)addr error:(NSError *)error
{
    std::cerr << __PRETTY_FUNCTION__ << " " << [[error localizedDescription] UTF8String] << std::endl;
}

@end

int
main(int argc,char ** argv)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    Sender * app = [[[Sender alloc] init] retain];
    app.thing = (GKOSCClient< ThingInterface > *)[[GKOSCClient alloc] initWithMapping:Thing_mapping];
    
    GKOSCUDPTransporter * t = [GKOSCUDPTransporter alloc];
    [app.thing addPacketTransporter:t];
    t.delegate = app;
    
    [t startConnectedToHostName:@"127.0.0.1" port:9200];
    
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    
    [pool release];
    
    return 0;
}