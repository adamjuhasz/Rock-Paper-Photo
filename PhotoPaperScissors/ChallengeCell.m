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

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.opponentImageView.image = nil;
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
            self.opponentName.text = challenge.challenger.username;
            break;
        
        case Unknown:
            break;
    }
    
    self.challengeName.text = challenge.challengeName;
    self.roundNumber.text = [NSString stringWithFormat:@"%lu", (unsigned long)challenge.currentRoundNumber];
    if (challenge.challengeComplete) {
        self.roundNumber.text = @"C";
    }
}

@end
