//
//  AppDelegate.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/14/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "AppDelegate.h"
#import <Parse/Parse.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <Fabric/Fabric.h>
#import <DigitsKit/DigitsKit.h>
#import <Crashlytics/Crashlytics.h>
#import <UICKeyChainStore/UICKeyChainStore.h>
#import <Crashlytics/Answers.h>


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // [Optional] Power your app with Local Datastore. For more info, go to
    // https://parse.com/docs/ios_guide#localdatastore/iOS
    //[Parse enableLocalDatastore];
    
    [Fabric with:@[CrashlyticsKit, DigitsKit]];
    
    // Initialize Parse.
    [Parse setApplicationId:@"0QyTxtWAQ1ZS8vEGGb3igejidgXHsB5WgAb48ojL"
                  clientKey:@"iwRyJje13olG5OgZpXcXN0Xj4QxYJ4JmgOiEdhoD"];
    
    // [Optional] Track statistics around application opens.
    if (application.applicationState != UIApplicationStateBackground) {
        // Track an app open here if we launch with a push, unless
        // "content_available" was used to trigger a background push (introduced
        // in iOS 7). In that case, we skip tracking here to avoid double
        // counting the app-open.
        BOOL preBackgroundPush = ![application respondsToSelector:@selector(backgroundRefreshStatus)];
        BOOL oldPushHandlerOnly = ![self respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)];
        BOOL noPushPayload = ![launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (preBackgroundPush || oldPushHandlerOnly || noPushPayload) {
            [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
        }
    }

    [PFFacebookUtils initializeFacebookWithApplicationLaunchOptions:launchOptions];
    [FBSDKAppEvents activateApp];
    [FBSDKProfile enableUpdatesOnAccessTokenChange:YES];
    
    [PFTwitterUtils initializeWithConsumerKey:@"MswULT6L6nMik6uyIszhgZ6C8"
                               consumerSecret:@"zmrMnAIbt5v6vZHaOb87GxDDjnVM7uZk2luIuXTGVZM1okMzwm"];
    
    NSError* configureError;
    [[GGLContext sharedInstance] configureWithError: &configureError];
    NSAssert(!configureError, @"Error configuring Google services: %@", configureError);
    
    [GIDSignIn sharedInstance].delegate = self;

    
    //[[PFUser currentUser] fetch];
    [[UINavigationBar appearance] setTitleTextAttributes: @{
                                                            NSForegroundColorAttributeName : [UIColor whiteColor],
                                                            NSFontAttributeName : [UIFont fontWithName:@"Montserrat-Light" size:18.0]
                                                            }];
    
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser) {
        //[[UIApplication sharedApplication] registerForRemoteNotifications];
        //[PFConfig getConfigInBackground];
    } else {
#ifndef DEBUG
        UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:@"iCloud.io.ajuhasz.rpp.icloud"];
        
        NSString *username = keychain[@"username"];
        NSString *password = keychain[@"password"];
        if (username && password) {
            NSError *errorLoggingIn;
            [PFUser logInWithUsername:username password:password error:&errorLoggingIn];
            if (errorLoggingIn) {
                [keychain removeItemForKey:@"username"];
                [keychain removeItemForKey:@"password"];
            } else {
                [FBSDKAppEvents logEvent:@"login"
                              parameters:[NSDictionary dictionaryWithObject:@"keychain" forKey:FBSDKAppEventParameterNameRegistrationMethod]];
                [Answers logLoginWithMethod:@"keychain"
                                    success:@(YES)
                           customAttributes:nil];
            }
        }
#endif
    }
    
    if ([[UIApplication sharedApplication] currentUserNotificationSettings]) {
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [FBSDKAppEvents activateApp];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Store the deviceToken in the current Installation and save it to Parse
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    currentInstallation[@"user"] = [PFUser currentUser];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"FAILED to register for notifications");
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    
    if ([userInfo objectForKey:@"badge"]) {
        NSInteger badgeNumber = [[userInfo objectForKey:@"badge"] integerValue];
        [application setApplicationIconBadgeNumber:badgeNumber];
    }
    
    if (application.applicationState == UIApplicationStateActive) {
        //show a notification
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updateChallanges" object:nil];
    }
    
    if (application.applicationState == UIApplicationStateInactive) {
        [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    }
    
    [Answers logCustomEventWithName:@"Open Push" customAttributes:userInfo];
    
    if (completionHandler) {
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if (application.applicationState == UIApplicationStateInactive) {
        // The application was just brought from the background to the foreground,
        // so we consider the app as having been "opened by a push notification."
        [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    }
    if ([userInfo objectForKey:@"badge"]) {
        NSInteger badgeNumber = [[userInfo objectForKey:@"badge"] integerValue];
        [application setApplicationIconBadgeNumber:badgeNumber];
    }
    
    if (application.applicationState == UIApplicationStateActive) {
        //show a notification
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updateChallanges" object:nil];
    }
    
    [Answers logCustomEventWithName:@"Open Push" customAttributes:userInfo];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    if  ([[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation])
    {
        return YES;
    }
    
    if ([[GIDSignIn sharedInstance] handleURL:url
                               sourceApplication:sourceApplication
                                   annotation:annotation])
    {
        return YES;
    }
    
    [Answers logCustomEventWithName:@"Open From URL" customAttributes:@{@"URL": url,
                                                                        @"Source Application": sourceApplication}];
    
    return YES;
}

- (void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user withError:(NSError *)error {
    // Perform any operations on signed in user here.
    [Answers logCustomEventWithName:@"Social Network Connect" customAttributes:@{@"Network": @"Google"}];
}

- (void)signIn:(GIDSignIn *)signIn didDisconnectWithUser:(GIDGoogleUser *)user withError:(NSError *)error {
    // Perform any operations when the user disconnects from app here.
    // ...
}

@end
