//
//  ChallengeModernCell.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/21/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "ChallengeModernCell.h"
#import <Colours/Colours.h>

@implementation ChallengeModernCell

- (void)awakeFromNib
{
    [self commonInit];
}

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
    
    self.opponentImageView.clipsToBounds = YES;
    self.opponentImageView.layer.cornerRadius = self.opponentImageView.bounds.size.width/2.0;
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    
    [self commonChangeSize];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    [self commonChangeSize];
}

- (void)commonChangeSize
{
     self.opponentImageView.layer.cornerRadius = self.opponentImageView.bounds.size.width/2.0;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    
}

- (void)prepareForReuse
{
    self.roundIndictorHolder.hidden = NO;
    self.roundIndicatorLabel.text = @"";
    self.opponentImageView.image = nil;
    self.competitorNameLabel.text = @"";
    self.challengeNameLabel.text = @"";
}

- (void)loadWithChallenge:(Challenge*)challenge
{
    self.opponentImageView.file = challenge.competitor[@"image"];
    [self.opponentImageView loadInBackground];
    self.competitorNameLabel.text = challenge.competitor[@"nickname"];
    
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
