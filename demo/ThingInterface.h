#ifndef ThingInterface_H
#define ThingInterface_H

#import <GKOSC.h>

static struct GKOSCMapItem Thing_mapping[] = {
    { @"hello",@"sf",@selector(hello:value:) },
    { @"goodbye",@"bf",@selector(goodbye:value:) },
    { 0,0,0 }
};

struct xyz {
    float x, y, z;
    
    xyz(float _x,float _y,float _z)
    : x(_x), y(_y), z(_z) {
    }
};

@protocol ThingInterface
- (void) hello:(NSString *)n value:(float)t;
- (void) goodbye:(NSData *)x value:(float)t;
@end

#endif