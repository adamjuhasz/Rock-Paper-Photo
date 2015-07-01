//
//  ChallengeModernCell.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/21/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "ChallengeModernCell.h"
#import <Colours/Colours.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@implementation ChallengeModernCell

- (void)awakeFromNib
{
    [self commonInit];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
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
    
    //these can change due to user action
    [[RACObserve(challenge, whosTurn) takeUntil:self.rac_prepareForReuseSignal] subscribeNext:^(id x) {
        [self configureTurnStyle:challenge];
    }];
    
    [[RACObserve(challenge, currentRoundNumber) takeUntil:self.rac_prepareForReuseSignal] subscribeNext:^(NSNumber *roundNumber) {
        _roundIndicatorLabel.text = [NSString stringWithFormat:@"%@", roundNumber];
    }];
    
}

- (void)configureTurnStyle:(Challenge*)theChallenge
{
    if (theChallenge.challengeComplete) {
        //challenge complete
        self.roundIndicatorLabel.text = @"C";
        self.roundIndictorHolder.hidden = YES;
    } else if (theChallenge.whosTurn == myTurn || theChallenge.whosTurn == noonesTurn) {
        //waiting for my turn
        self.roundIndictorHolder.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    } else {
        self.roundIndictorHolder.backgroundColor = [UIColor clearColor];
    }
}

@end
