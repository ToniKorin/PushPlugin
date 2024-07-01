/*
 Copyright 2009-2011 Urban Airship Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2. Redistributions in binaryform must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided withthe distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE URBAN AIRSHIP INC``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 EVENT SHALL URBAN AIRSHIP INC OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PushPlugin.h"
#import "VBSingleton.h"

@implementation PushPlugin : CDVPlugin

@synthesize notificationMessage;
@synthesize isInline;

@synthesize callbackId;
@synthesize notificationCallbackId;	
@synthesize callback;
@synthesize locationManager;

- (void)unregister:(CDVInvokedUrlCommand*)command;
{
    self.callbackId = command.callbackId;
    
    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
    [self successWithMessage:@"unregistered"];
}

- (void)register:(CDVInvokedUrlCommand*)command;
{
    NSLog(@"PushPlugin.register: 1");
    self.callbackId = command.callbackId;
    NSMutableDictionary* options = [command.arguments objectAtIndex:0];
    self.callback = [options objectForKey:@"ecb"];
    NSString *locatinPush = [options objectForKey:@"locationPush"];
    UNAuthorizationOptions authOptions =
                    UNAuthorizationOptionAlert
                    | UNAuthorizationOptionSound
                    | UNAuthorizationOptionBadge;
    [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:authOptions completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (granted)
        {
            NSLog(@"PushPlugin.register: GRANTED");
        }
        // Request token always, even if not granted
        if (locatinPush) { // Location Push Notification
            [self setupLocationManager];

        } else { // Remote Push Notification
            [self performSelectorOnMainThread:@selector(registerForRemoteNotifications)
                                   withObject:nil
                                waitUntilDone:NO];
        }
    }];
    // TODO https://gist.github.com/blitzcrank/d7f4034b6231df06d0f63bdd1ee7c172
    // https://github.com/moodlemobile/phonegap-plugin-push/blob/master/src/ios/PushPlugin.m
    NSLog(@"PushPlugin.register: 2");
    //if (notificationMessage)			// if there is a pending startup notification
    //	[self notificationReceived];	// go ahead and process it
}

- (void)registerForRemoteNotifications
{
    NSLog(@"PushPlugin.registerForRemoteNotifications: ....");
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

- (void)setupLocationManager {
    NSLog(@"PushPlugin.setupLocationManager");
    locationManager = [[CLLocationManager alloc] init];
    //locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.allowsBackgroundLocationUpdates = YES;
    //locationManager.distanceFilter = 200.0;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.locationManager requestAlwaysAuthorization];
    });
    [self startMonitoringLocationPush];
}

- (void)startMonitoringLocationPush {
    NSLog(@"PushPlugin.startMonitoringLocationPush: 2");
    [locationManager startMonitoringLocationPushesWithCompletion:^(NSData * _Nullable deviceToken, NSError * _Nullable error) {
        NSLog(@"PushPlugin.startMonitoringLocationPushesWithCompletion");
        if (error) {
            NSLog(@"errors %@", error.localizedDescription);
            [self failWithMessage:@"" withError:error];
            return;
        }
        if (!deviceToken) {
            [self failWithMessage:@"token missing" withError:nil];
            return;
        }
        NSLog(@"PushPlugin.locationToken: success");
        NSString *token = [PushPlugin stringFromDeviceToken:deviceToken];
        [self successWithMessage:[NSString stringWithFormat:@"%@", token]];
    }];
}
/*
 - (void)isEnabled:(NSMutableArray *)arguments withDict:(NSMutableDictionary *)options {
 UIRemoteNotificationType type = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
 NSString *jsStatement = [NSString stringWithFormat:@"navigator.PushPlugin.isEnabled = %d;", type != UIRemoteNotificationTypeNone];
 NSLog(@"JSStatement %@",jsStatement);
 }
 */

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken 
{
    NSLog(@"PushPlugin.token: 1");
    NSString *token = [PushPlugin stringFromDeviceToken:deviceToken];
    if (isInline)
        [self successWithMessage:[NSString stringWithFormat:@"%@", token]];
    else
        [self successWithMessage:@"{"];
    
    if (notificationMessage)			// if there is a pending startup notification
        [self notificationReceived];	// go ahead and process it
    NSLog(@"PushPlugin.token: done");
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [self failWithMessage:@"" withError:error];
}

- (void)notificationReceived 
{
    NSLog(@"Notification received");
    if (notificationMessage && self.callback)
    {
        NSMutableString *jsonStr = [NSMutableString stringWithString:@"{"];
        [self parseDictionary:notificationMessage intoJSON:jsonStr];
        if (isInline)
        {
            [jsonStr appendFormat:@"foreground:\"%d\"", 1];
            isInline = NO;
        }
        else {
            [jsonStr appendFormat:@"foreground:\"%d\"", 0];
        }
        [jsonStr appendString:@"}"];
        NSLog(@"Msg: %@", jsonStr);
        // send notification content to main js process
        NSString * jsCallBack = [NSString stringWithFormat:@"%@(%@);", self.callback, jsonStr];
        [self.commandDelegate evalJs:jsCallBack];
        // get javascript function to fire in background mode
        CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonStr];
        [self.commandDelegate sendPluginResult:commandResult callbackId:self.callbackId];
        
        self.notificationMessage = nil;
    }
}


// reentrant method to drill down and surface all sub-dictionaries' key/value pairs into the top level json
-(void)parseDictionary:(NSDictionary *)inDictionary intoJSON:(NSMutableString *)jsonString
{
    NSArray         *keys = [inDictionary allKeys];
    NSString        *key;
    
    for (key in keys)
    {
        id thisObject = [inDictionary objectForKey:key];
        
        if ([thisObject isKindOfClass:[NSDictionary class]])
            [self parseDictionary:thisObject intoJSON:jsonString];
        else if ([thisObject isKindOfClass:[NSString class]])
            [jsonString appendFormat:@"\"%@\":\"%@\",",
             key,
             [[[[inDictionary objectForKey:key]
                stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"]
               stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]
              stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"]];
        else {
            [jsonString appendFormat:@"\"%@\":\"%@\",", key, [inDictionary objectForKey:key]];
        }
    }
}

- (void)setApplicationIconBadgeNumber:(CDVInvokedUrlCommand *)command 
{
    NSLog(@"PushPlugin.setBadgeNumber");
    self.callbackId = command.callbackId;
    NSMutableDictionary* options = [command.arguments objectAtIndex:0];
    int badge = [[options objectForKey:@"badge"] intValue] ?: 0;
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:badge];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setInteger:badge forKey:@"badgeCount"];
    [prefs synchronize];
    [self successWithMessage:[NSString stringWithFormat:@"app badge count set to %d", badge]];
}

-(void)successWithMessage:(NSString *)message
{
    if (self.callbackId != nil)
    {
        CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];
        [self.commandDelegate sendPluginResult:commandResult callbackId:self.callbackId];
    }
}

-(void)failWithMessage:(NSString *)message withError:(NSError *)error
{
    NSString        *errorMessage = (error) ? [NSString stringWithFormat:@"%@ - %@", message, [error localizedDescription]] : message;
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage];
    [self.commandDelegate sendPluginResult:commandResult callbackId:self.callbackId];
}

- (void)didCompleteBackgroundProcess:(CDVInvokedUrlCommand*)command 
{
    NSLog(@"didCompleteBackgroundProcess called - calling background handler %lx",(unsigned long)[VBSingleton sharedInstance].backgroundHandler);
    if ([VBSingleton sharedInstance].backgroundHandler != nil) {
        [VBSingleton sharedInstance].backgroundHandler(UIBackgroundFetchResultNewData);
        [VBSingleton sharedInstance].backgroundHandler = nil;
    }
}

- (void)pluginInitialize
{
    NSLog(@"PushPlugin.pluginInitialize called");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishLaunching:) name:UIApplicationDidFinishLaunchingNotification object:nil];
}

- (void)finishLaunching:(NSNotification *)notification
{
    NSLog(@"PushPlugin.finishLaunching called");
    self.notificationMessage = notification.userInfo;
}

//
// Some essential diagnostic services
//

// Open app iOS settings view
- (void) switchToSettings: (CDVInvokedUrlCommand*)command
{
    self.callbackId = command.callbackId;
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: UIApplicationOpenSettingsURLString] options:@{} completionHandler:^(BOOL success) {
        if (success) {
            [self successWithMessage:@"OK"];
        }else{
            [self failWithMessage:@"NOK" withError:nil];
        }
    }];
}

// Background refresh status
- (void) getBackgroundRefreshStatus: (CDVInvokedUrlCommand*)command
{
    self.callbackId = command.callbackId;
    UIBackgroundRefreshStatus backgroundTaskStatus = [[UIApplication sharedApplication] backgroundRefreshStatus];
    NSString* status;
    if (backgroundTaskStatus == UIBackgroundRefreshStatusAvailable) {
        // Background task execution available for the app, triggered by remote-notification
        status = @"GRANTED";
    }else if(backgroundTaskStatus == UIBackgroundRefreshStatusDenied){
        // The user explicitly disabled background behavior for this app or for the whole system
        status = @"DENIED";
    }else if(backgroundTaskStatus == UIBackgroundRefreshStatusRestricted){
        // Background updates are unavailable and the user cannot enable them again. 
        // For example, this status can occur when parental controls are in effect for the current user
        status = @"RESTRICTED";
    }
    [self successWithMessage:status];
}

// Low power mode status
- (void) getLowPowerModeStatus: (CDVInvokedUrlCommand*)command
{
    self.callbackId = command.callbackId;
    NSString* status;
    if ([[NSProcessInfo processInfo] isLowPowerModeEnabled]) {
        // Low Power Mode is enabled. Start reducing activity to conserve energy.
        // E.g. remote-notification cannot trigger background task anymore
        status = @"ENABLED";
    } else {
        // Low Power Mode is not enabled.
        status = @"DISABLED";
    };
    [self successWithMessage:status];
}

// Location service status
- (void) getLocationServiceStatus: (CDVInvokedUrlCommand*)command
{
    self.callbackId = command.callbackId;
    NSString* status;
    if ([CLLocationManager locationServicesEnabled])
    {
        CLAuthorizationStatus authStatus = [CLLocationManager authorizationStatus];;
        if(authStatus == kCLAuthorizationStatusAuthorizedAlways){
            // When running in background (or foreground) 
            status = @"GRANTED";
        }else if(authStatus == kCLAuthorizationStatusAuthorizedWhenInUse){
            // Only when running in foreground
            status = @"ONLY_WHEN_IN_USE";
        }else if(authStatus == kCLAuthorizationStatusDenied || authStatus == kCLAuthorizationStatusRestricted){
            status = @"DENIED";
        }else if(authStatus == kCLAuthorizationStatusNotDetermined){
            status = @"NOT_DETERMINED";
        }
    }else { 
        status = @"DISABLED";
    }
    [self successWithMessage:status];
}

// Set configuration for location push type
- (void) setConfiguration:(CDVInvokedUrlCommand *)command
{
    //self.callbackId = command.callbackId;
    NSLog(@"PushPlugin.setConfiguration");
    NSMutableDictionary* config = [command.arguments objectAtIndex:0];
    NSError * err;
    NSData * jsonData = [NSJSONSerialization  dataWithJSONObject:config options:0 error:&err];
    NSString * configStr = [[NSString alloc] initWithData:jsonData   encoding:NSUTF8StringEncoding];

    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setValue:configStr forKey:@"config"];
    [prefs synchronize];
    //[self successWithMessage:@"OK"];
}

// Get and clear history for location push type
- (void) getAndClearHistory:(CDVInvokedUrlCommand *)command
{
    NSLog(@"PushPlugin.getAndClearHistory");
    self.callbackId = command.callbackId;
    // read
    NSUserDefaults * prefs = [NSUserDefaults standardUserDefaults];
    NSString * historyStr = [prefs valueForKey:@"history"];
    if (historyStr == nil) {
        historyStr = @"{}";
    }
    // clear
    [prefs setValue:@"{}" forKey:@"history"];
    [prefs synchronize];

    [self successWithMessage:historyStr];
}

// Timestamp of app active state for location push extension
- (void) setActiveState:(CDVInvokedUrlCommand *)command
{
    NSLog(@"PushPlugin.setActiveState");
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[NSDate date] forKey:@"active"];
    [prefs synchronize];
}

// App in-active state for location extension
- (void) setInActiveState:(CDVInvokedUrlCommand *)command
{
    NSLog(@"PushPlugin.setInActiveState");
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs removeObjectForKey:@"active"];
    [prefs synchronize];
}

+ (NSString *)stringFromDeviceToken:(NSData *)deviceToken {
#if defined(__IPHONE_13_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0
    NSUInteger length = deviceToken.length;
    if (length == 0) {
        return nil;
    }
    const unsigned char *buffer = (const unsigned char *)deviceToken.bytes;
    NSMutableString *hexString  = [NSMutableString stringWithCapacity:(length * 2)];
    for (int i = 0; i < length; ++i) {
        [hexString appendFormat:@"%02x", buffer[i]];
    }
    return [hexString copy];
#else
    NSString *token = [[[[deviceToken description] stringByReplacingOccurrencesOfString:@"<"withString:@""]
                    stringByReplacingOccurrencesOfString:@">" withString:@""]
                   stringByReplacingOccurrencesOfString: @" " withString: @""];
    return token;
#endif
}



@end
