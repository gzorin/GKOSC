#ifndef Thing_H
#define Thing_H

struct GKOSCMapItem Thing_mapping[] = {
    { @"hello",@"if",@selector(hello:value:) },
    { @"goodbye",@"if",@selector(goodbye:value:) },
    { 0,0,0 }
};

@protocol Thing
- (void) hello:(int32_t)x value:(float)t;
- (void) goodbye:(int32_t)x value:(float)t;
@end

#endif