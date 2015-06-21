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
{
    NSMutableArray *photoImageViews;
    NSMutableArray *photoRoundIndicatorViews;
}
@property IBOutlet UIScrollView *embededPhotos;

@property Challenge *theChallenge;
@property NSInteger showChallengeRound;

@end
