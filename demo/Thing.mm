#import "Thing.h"

#include <iostream>

@implementation Thing
- (void) hello:(int32_t)x value:(float)t;
{
    std::cerr << "hello: " << x << " " << t << std::endl;
}

- (void) goodbye:(int32_t)x value:(float)t;
{
    std::cerr << "goodbye: " << x << " " << t << std::endl;
}
@end