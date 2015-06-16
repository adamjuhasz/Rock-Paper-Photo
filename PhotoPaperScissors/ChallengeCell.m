//
//  CollectionCell.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/16/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "ChallengeCell.h"

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
            self.opponentImageView.file = challenge.challengee[@"image"];
            [self.opponentImageView loadInBackground];
            self.opponentName.text = challenge.challengee.username;
            break;
            
       case Challengee:
            self.opponentImageView.file = challenge.challenger[@"image"];
            [self.opponentImageView loadInBackground];
            self.opponentName.text = challenge.challenger.username;
            break;
        
        case Unknown:
            break;
    }
    
    self.challengeName.text = challenge.challengeName;
    self.roundNumber.text = [NSString stringWithFormat:@"%lu", (unsigned long)challenge.currentRoundNumber];
}

@end
