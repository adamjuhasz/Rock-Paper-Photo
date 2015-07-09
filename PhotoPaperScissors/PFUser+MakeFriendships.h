//
//  PFUser+MakeFriendships.h
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/20/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import <Parse/Parse.h>

@interface PFUser (MakeFriendships)

+ (void)AJMakeFriendsWithUsersWithQuery:(PFQuery*)query source:(NSString*)source withCompletion:(void (^)(NSNumber*))completionBlock;

@end
