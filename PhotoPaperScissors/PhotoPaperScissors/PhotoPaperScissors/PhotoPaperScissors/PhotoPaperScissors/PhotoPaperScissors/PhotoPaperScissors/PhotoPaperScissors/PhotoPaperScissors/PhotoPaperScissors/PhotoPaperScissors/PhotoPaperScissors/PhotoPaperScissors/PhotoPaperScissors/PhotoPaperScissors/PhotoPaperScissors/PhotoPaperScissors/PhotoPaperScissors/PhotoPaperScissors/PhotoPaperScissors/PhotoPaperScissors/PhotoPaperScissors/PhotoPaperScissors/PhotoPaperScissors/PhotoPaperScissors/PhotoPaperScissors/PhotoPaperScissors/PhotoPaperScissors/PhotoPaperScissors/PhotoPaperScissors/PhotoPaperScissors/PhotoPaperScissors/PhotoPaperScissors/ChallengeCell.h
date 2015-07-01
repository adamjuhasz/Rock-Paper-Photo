//
//  CollectionCell.h
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/16/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "PFTableViewCell.h"
#import "Challenge.h"

@interface ChallengeCell : PFTableViewCell

@property IBOutlet PFImageView *opponentImageView;
@property IBOutlet UILabel *challengeNameLabel;
@property IBOutlet UILabel *competitorNameLabel;
@property IBOutlet UILabel *roundIndicatorLabel;
@property IBOutlet UIView *roundIndictorHolder;

@property IBOutlet UIView *innerRectangle;
@property IBOutlet UILabel *timeIndicator;

- (void)loadWithChallenge:(Challenge*)challenge;

@end
