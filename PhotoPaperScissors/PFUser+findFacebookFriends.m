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

#import "PFAnalytics+PFAnalytics_TrackError.h"

@implementation PFUser (findFacebookFriends)

+ (void)findFacebookFriends
{
    if ([FBSDKAccessToken currentAccessToken] == nil) {
        NSArray *permissions = @[@"public_profile", @"user_friends"];
        [PFFacebookUtils linkUserInBackground:[PFUser currentUser] withReadPermissions:permissions block:^(BOOL succeeded, NSError *PF_NULLABLE_S error){
            if (error) {
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
        return;
    }
    
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                  initWithGraphPath:@"/me/friends"
                                  parameters:nil
                                  HTTPMethod:@"GET"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                          id result,
                                          NSError *error) {
        // Handle the result
        NSMutableArray *array = [NSMutableArray array];
        for (NSDictionary *aFriend in result[@"data"]) {
            [array addObject:aFriend[@"id"]];
        }
        
        PFQuery *userQuery = [PFUser query];
        [userQuery whereKey:@"FBID" containedIn:array];
        [userQuery findObjectsInBackgroundWithBlock:^(NSArray *PF_NULLABLE_S facebookFriendsUsingRPP, NSError *PF_NULLABLE_S error){
            if (error) {
                return;
            }
            
            if (facebookFriendsUsingRPP.count == 0) {
                NSString *string = [NSString stringWithFormat:@"Found %d new friends through Facebook", 0];
                UIAlertView *alerting = [[UIAlertView alloc] initWithTitle:@"Facebook"
                                                                   message:string
                                                                  delegate:self
                                                         cancelButtonTitle:@"OK"
                                                         otherButtonTitles:nil];
                [alerting show];
                return;
            }
            
            PFQuery *friendsWithMeQuery = [PFQuery queryWithClassName:@"Relationship"];
            [friendsWithMeQuery whereKey:@"user" containedIn:facebookFriendsUsingRPP];
            [friendsWithMeQuery whereKey:@"friendsWith" equalTo:[PFUser currentUser]];
            //NSArray *t1 = [friendsWithMeQuery findObjects];
            
            PFQuery *friendsWithQuery = [PFQuery queryWithClassName:@"Relationship"];
            [friendsWithQuery whereKey:@"friendsWith" containedIn:facebookFriendsUsingRPP];
            [friendsWithQuery whereKey:@"user" equalTo:[PFUser currentUser]];
            //NSArray *t2 = [friendsWithQuery findObjects];
            
            PFQuery *compound = [PFQuery orQueryWithSubqueries:@[friendsWithMeQuery, friendsWithQuery]];
            [compound findObjectsInBackgroundWithBlock:^(NSArray *PF_NULLABLE_S existingFriendships, NSError *PF_NULLABLE_S error){
                if (error) {
                    return;
                }
                
                int friendsAdded = 0;
                for (PFUser *user in facebookFriendsUsingRPP) {
                    BOOL friendsAlready = NO;
                    for (PFObject *friendship in existingFriendships) {
                        PFUser *friender = friendship[@"user"];
                        PFUser *friendee = friendship[@"friendsWith"];
                        
                        if ([friender.objectId isEqualToString:user.objectId] ||
                            [friendee.objectId isEqualToString:user.objectId]) {
                            friendsAlready = YES;
                        }
                    }
                    
                    if (friendsAlready) {
                        continue;
                    }
                    
                    friendsAdded++;
                    
                    PFObject *friendhsip = [PFObject objectWithClassName:@"Relationship"];
                    friendhsip[@"createdBy"] = [PFUser currentUser];
                    friendhsip[@"user"] = [PFUser currentUser];
                    friendhsip[@"userId"] = [[PFUser currentUser] objectId];
                    
                    PFUser *theOtherUser = (PFUser*)user;
                    friendhsip[@"friendsWith"] = theOtherUser;
                    friendhsip[@"friendsWithId"] = theOtherUser.objectId;
                    [friendhsip saveInBackgroundWithBlock:^(BOOL succeeded, NSError *PF_NULLABLE_S error){
                        if (error) {
                            return;
                        }
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"newFriendsip" object:friendhsip];
                        PFQuery *userQuery = [PFInstallation query];
                        [userQuery whereKey:@"user" equalTo:theOtherUser];
                        NSString *alert = [NSString stringWithFormat:@"Your facebook friend %@(%@)) found you and has friended you",
                                           [[PFUser currentUser] objectForKey:@"nickname"],
                                           [[PFUser currentUser] objectForKey:@"FacebookName"]];
                        NSMutableDictionary *data = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                     @"alert", alert,
                                                     nil];
                        PFPush *push = [[PFPush alloc] init];
                        [push setData:data];
                        [push setQuery:userQuery];
                        [push sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError * __nullable error) {
                            if (error) {
                                NSLog(@"Error with push: %@", error);
                                [PFAnalytics trackErrorIn:@"findFacebookFriends" withComment:@"sendPushInBackgroundWithBlock" withError:error];
                                return;
                            }
                        }];
                    }];
                    
                    NSString *string = [NSString stringWithFormat:@"Found %d new friends through Facebook", friendsAdded];
                    UIAlertView *alerting = [[UIAlertView alloc] initWithTitle:@"Facebook"
                                               message:string
                                              delegate:self
                                     cancelButtonTitle:@"OK"
                                     otherButtonTitles:nil];
                    [alerting show];
                }
            }];
        }];
    }];
    
}

@end
