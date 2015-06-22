//
//  CollectionCell.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/16/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "ChallengeCell.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@implementation ChallengeCell

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self setRadius];
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    [self setRadius];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self setRadius];
}

- (void)setRadius
{
    self.innerRectangle.clipsToBounds = YES;
    self.innerRectangle.layer.cornerRadius = 3;
    
    self.opponentImageView.clipsToBounds = YES;
    self.opponentImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.opponentImageView.layer.cornerRadius = self.opponentImageView.bounds.size.width/2.0;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.opponentImageView.image = nil;
    self.roundContainer.backgroundColor = [UIColor clearColor];
}

- (void)loadWithChallenge:(Challenge*)challenge
{
    self.opponentImageView.file = challenge.competitor[@"image"];
    [self.opponentImageView loadInBackground];
    
    self.challengeName.text = challenge.challengeName;
    self.roundNumber.text = [NSString stringWithFormat:@"%lu", (unsigned long)challenge.currentRoundNumber];
    if (challenge.challengeComplete) {
        self.roundNumber.text = @"C";
    }
    
    if (challenge.challengeComplete) {
        //challenge complete
        self.roundContainer.backgroundColor = [UIColor blackColor];
    } else if (challenge.whosTurn == theirTurn) {
        //waiting for my turn
        self.roundContainer.backgroundColor = [UIColor colorWithRed:251/255.0 green:234/255.0 blue:153/255.0 alpha:1.0];
    } else if (challenge.whosTurn == myTurn) {
        //ready for next round
        self.roundContainer.backgroundColor = [UIColor colorWithRed:182/255.0 green:224/255.0 blue:148/255.0 alpha:1.0];
    }
    
}

@end
