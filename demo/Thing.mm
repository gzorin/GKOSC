#import "Thing.h"

#include <iostream>

@implementation Thing
- (void) hello:(NSString *)n value:(float)t;
{
    std::cerr << "hello: " << [n UTF8String] << " " << t << std::endl;
}

- (void) goodbye:(NSData *)data value:(float)t;
{
    xyz * pxyz = (xyz *)[data bytes];
    
    std::cerr << "goodbye: " << pxyz->x << "," << pxyz->y << "," << pxyz->z << " " << t << std::endl;
}
@end