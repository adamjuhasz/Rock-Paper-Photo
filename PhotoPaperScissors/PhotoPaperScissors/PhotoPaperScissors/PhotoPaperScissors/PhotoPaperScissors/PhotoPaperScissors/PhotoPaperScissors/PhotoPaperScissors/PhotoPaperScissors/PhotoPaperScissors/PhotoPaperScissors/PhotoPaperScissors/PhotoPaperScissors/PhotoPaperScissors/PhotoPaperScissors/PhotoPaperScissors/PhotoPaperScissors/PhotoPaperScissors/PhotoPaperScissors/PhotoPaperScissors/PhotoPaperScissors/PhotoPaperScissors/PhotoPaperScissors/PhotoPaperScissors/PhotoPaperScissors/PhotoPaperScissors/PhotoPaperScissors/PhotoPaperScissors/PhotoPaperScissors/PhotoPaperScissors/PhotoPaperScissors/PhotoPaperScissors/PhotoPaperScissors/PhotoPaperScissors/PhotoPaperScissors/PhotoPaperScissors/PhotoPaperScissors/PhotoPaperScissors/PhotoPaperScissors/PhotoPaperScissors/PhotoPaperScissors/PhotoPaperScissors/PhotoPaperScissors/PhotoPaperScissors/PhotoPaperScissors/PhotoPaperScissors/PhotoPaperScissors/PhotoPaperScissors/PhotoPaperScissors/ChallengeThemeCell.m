//
//  ChallengeThemeCell.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/30/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "ChallengeThemeCell.h"

@implementation ChallengeThemeCell

- (void)prepareForReuse
{
    self.themeImageView.image = nil;
    self.themeNameLabel.text = @"";
}

@end
