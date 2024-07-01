//
//  AppDelegate+notification.m
//  pushtest
//
//  Created by Robert Easterday on 10/26/12.
//
//

#import "AppDelegate+notification.h"
#import "VBSingleton.h"
#import "PushPlugin.h"
#import <objc/runtime.h>

static char launchNotificationKey;
NSString *const pushPluginApplicationDidBecomeActiveNotification = @"pushPluginApplicationDidBecomeActiveNotification";

@interface WeakObjectContainer<T> : NSObject

@property (nonatomic, readonly, weak) T object;

@end

@implementation WeakObjectContainer

- (instancetype) initWithObject:(id)object
{
    if (self = [super init]) {
        _object = object;
    }
    return self;
}

@end

@implementation AppDelegate (notification)

- (id) getCommandInstance:(NSString*)className
{
    return [self.viewController getCommandInstance:className];
}

// its dangerous to override a method from within a category.
// Instead we will use method swizzling. we set this up in the load call.
+ (void)load
{
    NSLog(@"AppDelegate.load");
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];

        SEL originalSelector = @selector(init);
        SEL swizzledSelector = @selector(pushPluginSwizzledInit);

        Method original = class_getInstanceMethod(class, originalSelector);
        Method swizzled = class_getInstanceMethod(class, swizzledSelector);

        BOOL didAddMethod =
        class_addMethod(class,
                        originalSelector,
                        method_getImplementation(swizzled),
                        method_getTypeEncoding(swizzled));

        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(original),
                                method_getTypeEncoding(original));
        } else {
            method_exchangeImplementations(original, swizzled);
        }
    });
}

- (AppDelegate *)pushPluginSwizzledInit
{
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushPluginOnApplicationDidBecomeActive:)
                                                 name:@"UIApplicationDidBecomeActiveNotification" object:nil];
    // on an overrided method, this is not recursive, although it appears that way. neat huh?
    return [self pushPluginSwizzledInit];
}


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"AppDelegate.TokenReceived");
    PushPlugin *pushHandler = [self getCommandInstance:@"PushPlugin"];
    if (application.applicationState == UIApplicationStateActive)
        pushHandler.isInline = YES;
    else
        pushHandler.isInline = NO;
    [pushHandler didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"App.TOKEN: ERROR");
    PushPlugin *pushHandler = [self getCommandInstance:@"PushPlugin"];
    [pushHandler didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler
{
    NSLog(@"AppDelegate.didReceiveNotification");
    PushPlugin *pushHandler = [self getCommandInstance:@"PushPlugin"];
    pushHandler.notificationMessage = userInfo;
    if (application.applicationState == UIApplicationStateActive)
        pushHandler.isInline = YES;
    else
        pushHandler.isInline = NO;
    [pushHandler notificationReceived];
    
    [VBSingleton sharedInstance].backgroundHandler = handler;
}

- (void)pushPluginOnApplicationDidBecomeActive:(NSNotification *)notification {
    
    NSLog(@"AppDelegate.becameActive");
    //zero badge
    UIApplication *application = notification.object;
    application.applicationIconBadgeNumber = 0;
    
    if (self.launchNotification) {
        PushPlugin *pushHandler = [self getCommandInstance:@"PushPlugin"];
        pushHandler.isInline = YES;
        pushHandler.notificationMessage = self.launchNotification;
        self.launchNotification = nil;
        [pushHandler performSelectorOnMainThread:@selector(notificationReceived) withObject:pushHandler waitUntilDone:NO];

        NSLog(@"AppDelegate.createNotifChecker");
        if (notification)
        {
            NSDictionary *launchOptions = [notification userInfo];
            if (launchOptions)
                self.launchNotification = [launchOptions objectForKey: @"UIApplicationLaunchOptionsRemoteNotificationKey"];
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:pushPluginApplicationDidBecomeActiveNotification object:nil];
}

// The accessors use an Associative Reference since you can't define a iVar in a category
// http://developer.apple.com/library/ios/#documentation/cocoa/conceptual/objectivec/Chapters/ocAssociativeReferences.html
- (NSMutableArray *)launchNotification
{
    return objc_getAssociatedObject(self, &launchNotificationKey);
}

- (void)setLaunchNotification:(NSDictionary *)aDictionary
{
    objc_setAssociatedObject(self, &launchNotificationKey, aDictionary, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)dealloc
{
    self.launchNotification    = nil; // clear the association and release the object
}

@end
