//
//  PhotoViewController.h
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/15/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Challenge.h"

@interface PhotoViewController : UIViewController

@property IBOutlet UIImageView *otherUserPhoto;
@property IBOutlet UIImageView *myPhoto;

@property UIImage *otherUserImage;
@property UIImage *myImage;

@property IBOutlet UIButton *nextAction;

@property Challenge *theChallenge;
@property NSInteger showChallengeRound;

@end
