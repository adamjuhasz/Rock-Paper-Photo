//
//  PFUser+MakeFriendships.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/20/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "PFUser+MakeFriendships.h"
#import "PFAnalytics+PFAnalytics_TrackError.h"

@implementation PFUser (MakeFriendships)

+ (void)AJMakeFriendsWithUsersWithQuery:(PFQuery*)query withCompletion:(void (^)(NSNumber*))completionBlock
{
    [query findObjectsInBackgroundWithBlock:^(NSArray *PF_NULLABLE_S usersMatchingCondition, NSError *PF_NULLABLE_S error){
        if (error) {
            NSLog(@"Error with AJMakeFriendsWithUsersWithQuery: %@", error);
            [PFAnalytics trackErrorIn:NSStringFromSelector(_cmd) withComment:@"findObjectsInBackgroundWithBlock" withError:error];
            return;
        }
        
        if (usersMatchingCondition.count == 0) {
            if (completionBlock) {
                completionBlock(@(usersMatchingCondition.count));
            }
            return;
        }
        
        PFQuery *friendsWithMeQuery = [PFQuery queryWithClassName:@"Relationship"];
        [friendsWithMeQuery whereKey:@"user" containedIn:usersMatchingCondition];
        [friendsWithMeQuery whereKey:@"friendsWith" equalTo:[PFUser currentUser]];
        
        PFQuery *friendsWithQuery = [PFQuery queryWithClassName:@"Relationship"];
        [friendsWithQuery whereKey:@"friendsWith" containedIn:usersMatchingCondition];
        [friendsWithQuery whereKey:@"user" equalTo:[PFUser currentUser]];
        
        PFQuery *compound = [PFQuery orQueryWithSubqueries:@[friendsWithMeQuery, friendsWithQuery]];
        [compound includeKey:@"user"];
        [compound includeKey:@"friendsWith"];
        [compound findObjectsInBackgroundWithBlock:^(NSArray *existingFriendships, NSError *error){
            if (error) {
                NSLog(@"Error with friendship query: %@", error);
                [PFAnalytics trackErrorIn:NSStringFromSelector(_cmd) withComment:@"findObjectsInBackgroundWithBlock" withError:error];
                return;
            }
            
            int friendsAdded = 0;
            for (PFUser *user in usersMatchingCondition) {
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
                
                [PFUser AJMakeFriendshipWith:user];
                friendsAdded++;
            }
            
            if (completionBlock) {
                completionBlock(@(friendsAdded));
            }
        }];
    }];
}

+ (void)AJMakeFriendshipWith:(PFUser*)user
{
    PFObject *friendhsip = [PFObject objectWithClassName:@"Relationship"];
    friendhsip[@"createdBy"] = [PFUser currentUser];
    friendhsip[@"user"] = [PFUser currentUser];
    friendhsip[@"userId"] = [[PFUser currentUser] objectId];
    
    PFUser *theOtherUser = (PFUser*)user;
    friendhsip[@"friendsWith"] = theOtherUser;
    friendhsip[@"friendsWithId"] = theOtherUser.objectId;
    [friendhsip saveInBackgroundWithBlock:^(BOOL succeeded, NSError *PF_NULLABLE_S error){
        if (error) {
            NSLog(@"Error with friendship creatio: %@", error);
            [PFAnalytics trackErrorIn:NSStringFromSelector(_cmd) withComment:@"saveInBackgroundWithBlock" withError:error];
            return;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"newFriendsip" object:friendhsip];
        [PFUser AJSendPushToUser:user];
    }];
    
}

+ (void)AJSendPushToUser:(PFUser*)user
{
    PFQuery *userQuery = [PFInstallation query];
    [userQuery whereKey:@"user" equalTo:user];
    NSString *alert = [NSString stringWithFormat:@"Your Facebook friend %@(%@)) found you and has friended you",
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
            [PFAnalytics trackErrorIn:NSStringFromSelector(_cmd) withComment:@"sendPushInBackgroundWithBlock" withError:error];
            return;
        }
    }];
}

@end
