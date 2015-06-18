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
        self.roundNumber.clipsToBounds = YES;
        self.roundNumber.layer.cornerRadius = self.roundNumber.bounds.size.width/2.0;
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.opponentImageView.image = nil;
    self.roundNumber.backgroundColor = [UIColor greenColor];
}

- (void)loadWithChallenge:(Challenge*)challenge
{
    switch (challenge.playerIAm) {
        case Challenger:
            if (challenge.challengee[@"image"]) {
                self.opponentImageView.file = challenge.challengee[@"image"];
                [self.opponentImageView loadInBackground];
            }
            self.opponentName.text = challenge.challengee.username;
            break;
            
       case Challengee:
            if (challenge.challenger[@"image"]) {
                self.opponentImageView.file = challenge.challenger[@"image"];
                [self.opponentImageView loadInBackground];
            }
            self.opponentName.text = challenge.challenger[@"nickname"];
            break;
        
        case Unknown:
            break;
    }
    
    self.challengeName.text = challenge.challengeName;
    self.roundNumber.text = [NSString stringWithFormat:@"%lu", (unsigned long)challenge.currentRoundNumber];
    if (challenge.challengeComplete) {
        self.roundNumber.text = @"C";
    }
    
    if ([challenge imageForPlayer:challenge.playerIAm forRound:challenge.currentRoundNumber] == nil) {
        self.roundNumber.backgroundColor = [UIColor yellowColor];
    }
    if ([challenge imageForPlayer:challenge.playerIAm forRound:challenge.currentRoundNumber] &&
        [challenge imageForPlayer:challenge.otherPlayerIs forRound:challenge.currentRoundNumber] &&
        challenge.currentRoundNumber < challenge.maxRounds) {
        self.roundNumber.backgroundColor = [UIColor yellowColor];
    }
    if (challenge.challengeComplete) {
        self.roundNumber.backgroundColor = [UIColor blackColor];
    }
}

@end
