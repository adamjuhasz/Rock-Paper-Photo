//
//  CurrentChallengesController.h
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/16/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import <ParseUI/ParseUI.h>
#import <Parse/Parse.h>

#define MinimumGradientSteps 7

@interface CurrentChallengesController : PFQueryTableViewController
{
    UIColor *gradientStartColor;
    UIColor *gradientEndColor;
    
    NSArray *gradientStartColorArray;
    NSArray *gradientEndColorArray;
    
    int gradientSteps;
}

- (UIColor*)colorForCellPosition:(NSIndexPath*)path;

@end
