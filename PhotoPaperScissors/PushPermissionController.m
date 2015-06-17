//
//  PushPermissionController.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/16/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "PushPermissionController.h"
#import <Parse/Parse.h>
//#import <JLPermissions/JLNotificationPermission.h>

@implementation PushPermissionController
/*
- (IBAction)yesForPermission:(id)sender
{
    JLNotificationPermission *permission = [[JLNotificationPermission alloc] init];
    [permission authorizeWithTitle:(NSString *)@"Send you challenges?"
                           message:(NSString *)@"This lets us let you know when someone challenges you or a new round starts."
                       cancelTitle:(NSString *)@"Not now"
                        grantTitle:(NSString *)@"Yes!"
                        completion:^(NSString *deviceID, NSError *error){
                            [self close:nil];
                        }];
}

- (IBAction)close:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}
*/
@end
