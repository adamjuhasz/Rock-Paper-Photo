//
//  PFUser+findFacebookFriends.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/19/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "PFUser+findFacebookFriends.h"
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>

#import "PFAnalytics+PFAnalytics_TrackError.h"
#import "PFUser+MakeFriendships.h"

@interface AJFaceBookDelegate : NSObject <UIAlertViewDelegate, FBSDKAppInviteDialogDelegate>

@end

@implementation AJFaceBookDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        FBSDKAppInviteContent *content =[[FBSDKAppInviteContent alloc] init];
        content.appLinkURL = [NSURL URLWithString:@"https://fb.me/1061624507343343"];
        //optionally set previewImageURL
        //content.appInvitePreviewImageURL = [NSURL URLWithString:@"https://www.mydomain.com/my_invite_image.jpg"];
        
        // present the dialog. Assumes self implements protocol `FBSDKAppInviteDialogDelegate`
        [FBSDKAppInviteDialog showWithContent:content delegate:self];
    }
}

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didCompleteWithResults:(NSDictionary *)results
{
    NSLog(@"appInviteDialog: %@", results);
}

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didFailWithError:(NSError *)error
{
    NSLog(@"Error with appInvite: %@", error);
    [PFAnalytics trackErrorIn:NSStringFromSelector(_cmd) withComment:nil withError:error];
    return;
}

@end

AJFaceBookDelegate *AJAlertDelegate;

@implementation PFUser (findFacebookFriends)

+ (void)findFacebookFriends
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        AJAlertDelegate = [[AJFaceBookDelegate alloc] init];
    });
    
    if ([FBSDKAccessToken currentAccessToken] == nil) {
        [PFUser AJLinkCurrentUserToFacebook];
        return;
    }
    
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                  initWithGraphPath:@"/me/friends"
                                  parameters:nil
                                  HTTPMethod:@"GET"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                          id result,
                                          NSError *error) {
        if (error) {
            NSLog(@"Error with startWithCompletionHandler: %@", error);
            [PFAnalytics trackErrorIn:NSStringFromSelector(_cmd) withComment:@"startWithCompletionHandler" withError:error];
            return;
        }
        
        // Handle the result
        NSMutableArray *array = [NSMutableArray array];
        for (NSDictionary *aFriend in result[@"data"]) {
            [array addObject:aFriend[@"id"]];
        }
        
        if (array.count == 0) {
            [PFUser AJDisplayFacebookAlertWithCount:0];
            return;
        }
        
        PFQuery *userQuery = [PFUser query];
        [userQuery whereKey:@"FBID" containedIn:array];
        [PFUser AJMakeFriendsWithUsersWithQuery:userQuery
                                 withCompletion:^(NSNumber *count) {
                                     [PFUser AJDisplayFacebookAlertWithCount:count.integerValue];
        }];
    }];
    
}

+ (void)AJDisplayFacebookAlertWithCount:(NSInteger)count
{
    NSString *string = [NSString stringWithFormat:@"Found %ld new friends through Facebook", (long)count];
    UIAlertView *alerting = [[UIAlertView alloc] initWithTitle:@"Facebook"
                                                       message:string
                                                      delegate:AJAlertDelegate
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:@"Invite More", nil];
    [alerting show];
}

+ (void)AJLinkCurrentUserToFacebook
{
    NSArray *permissions = @[@"public_profile", @"user_friends"];
    [PFFacebookUtils linkUserInBackground:[PFUser currentUser] withReadPermissions:permissions block:^(BOOL succeeded, NSError *PF_NULLABLE_S error){
        if (error) {
            NSLog(@"Error with linkUserInBackground: %@", error);
            [PFAnalytics trackErrorIn:NSStringFromSelector(_cmd) withComment:@"linkUserInBackground" withError:error];
            return;
        }
        
        if (!succeeded) {
            return;
        }
        if ([FBSDKAccessToken currentAccessToken]) {
            FBSDKGraphRequest *meRequest = [[FBSDKGraphRequest alloc]
                                            initWithGraphPath:@"/me"
                                            parameters:nil
                                            HTTPMethod:@"GET"];
            [meRequest startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                                    id result,
                                                    NSError *error) {
                // Handle the result
                NSLog(@"%@", result);
                if (result[@"id"]) {
                    PFUser *currentUser = [PFUser currentUser];
                    currentUser[@"FBID"] = result[@"id"];
                    currentUser[@"FacebookName"] = result[@"name"];
                    [currentUser saveInBackground];
                }
            }];
            
            [self findFacebookFriends];
        }
    }];
}

@end
