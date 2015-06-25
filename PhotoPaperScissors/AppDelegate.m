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


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // [Optional] Power your app with Local Datastore. For more info, go to
    // https://parse.com/docs/ios_guide#localdatastore/iOS
    //[Parse enableLocalDatastore];
    
#ifdef DEBUG
    [Fabric with:@[DigitsKit]];
#else
    [Fabric with:@[CrashlyticsKit, DigitsKit]];
#endif
    
    // Initialize Parse.
    [Parse setApplicationId:@"0QyTxtWAQ1ZS8vEGGb3igejidgXHsB5WgAb48ojL"
                  clientKey:@"iwRyJje13olG5OgZpXcXN0Xj4QxYJ4JmgOiEdhoD"];
    
    // [Optional] Track statistics around application opens.
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    [PFConfig getConfigInBackgroundWithBlock:^(PFConfig *config, NSError *error) {
        if (error) {
            NSLog(@"Failed to fetch. Using Cached Config.");
        }
    }];

    [PFFacebookUtils initializeFacebookWithApplicationLaunchOptions:launchOptions];
    [FBSDKAppEvents activateApp];
    [FBSDKProfile enableUpdatesOnAccessTokenChange:YES];
    
    [PFTwitterUtils initializeWithConsumerKey:@"MswULT6L6nMik6uyIszhgZ6C8" consumerSecret:@"zmrMnAIbt5v6vZHaOb87GxDDjnVM7uZk2luIuXTGVZM1okMzwm"];
    
    //[[PFUser currentUser] fetch];
    
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser) {
        //[[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:@"iCloud.io.ajuhasz.rpp.icloud"];
        keychain.synchronizable = YES;
        
        NSString *username = keychain[@"username"];
        NSString *password = keychain[@"password"];
        if (username && password) {
            [PFUser logInWithUsername:username password:password];
        }
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
    
    // Create empty photo object
    /*
     NSString *photoId = [userInfo objectForKey:@"p"];
     PFObject *targetPhoto = [PFObject objectWithoutDataWithClassName:@"Photo"   objectId:photoId];
     */
    // Fetch photo object
    /*[targetPhoto fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        // Show photo view controller
        if (error) {
            handler(UIBackgroundFetchResultFailed);
        } else if ([PFUser currentUser]) {
            PhotoVC *viewController = [[PhotoVC alloc] initWithPhoto:object];
            [self.navController pushViewController:viewController animated:YES];
            handler(UIBackgroundFetchResultNewData);
        } else {
            handler(UIBackgroundModeNoData);
        }
    }];*/
    
    completionHandler(UIBackgroundFetchResultNoData);
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation];
}

@end
