#import <Foundation/Foundation.h>

@interface VBSingleton : NSObject

@property (strong,nonatomic) void (^backgroundHandler)(UIBackgroundFetchResult result);

+ (VBSingleton*)sharedInstance;

@end