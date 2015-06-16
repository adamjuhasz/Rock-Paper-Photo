//
//  ChallengeListController.h
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/15/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface ChallengeOptionsController : UITableViewController
{
    NSArray *challenges;
}

@property PFUser *challengee;

@end
