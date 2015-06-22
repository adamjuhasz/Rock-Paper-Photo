//
//  ChallengeModernCell.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/21/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "ChallengeModernCell.h"

@implementation ChallengeModernCell

- (id)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.roundIndictorHolder.layer.cornerRadius = self.roundIndictorHolder.bounds.size.width/2.0;
    self.roundIndictorHolder.clipsToBounds = YES;
}

- (void)prepareForReuse
{
    self.roundIndictorHolder.hidden = NO;
    self.roundIndicatorLabel.text = @"";
    self.competitorImageView.image = nil;
    self.competitorNameLabel.text = @"";
    self.challengeNameLabel.text = @"";
}

- (void)loadWithChallenge:(Challenge*)challenge
{
    self.competitorImageView.file = challenge.competitor[@"image"];
    [self.competitorImageView loadInBackground];
    self.competitorNameLabel.text = challenge.competitor[@"name"];
    
    self.challengeNameLabel.text = challenge.challengeName;
    self.roundIndicatorLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)challenge.currentRoundNumber];
    if (challenge.challengeComplete) {
        self.roundIndicatorLabel.text = @"C";
    }
    
    if (challenge.challengeComplete) {
        //challenge complete
        self.roundIndictorHolder.hidden = YES;
    } else if (challenge.whosTurn == myTurn) {
        //waiting for my turn
        self.roundIndictorHolder.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    } else {
        self.roundIndictorHolder.backgroundColor = [UIColor clearColor];
    }
}

@end
