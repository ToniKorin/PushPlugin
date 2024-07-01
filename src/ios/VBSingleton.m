#import "VBSingleton.h"

@implementation VBSingleton

+ (VBSingleton*)sharedInstance
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        NSLog(@"%@",@"VBSingleton Shared first call");
        _sharedObject = [[VBSingleton alloc] init];
    });
    return _sharedObject;
}

@end