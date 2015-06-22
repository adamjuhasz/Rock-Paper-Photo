//
//  ChallengeModernCell.h
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/21/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "PFCollectionViewCell.h"
#import <ParseUI/ParseUI.h>
#import "Challenge.h"

@interface ChallengeModernCell : PFTableViewCell

@property IBOutlet UIView *roundIndictorHolder;
@property IBOutlet UILabel *roundIndicatorLabel;
@property IBOutlet PFImageView *competitorImageView;
@property IBOutlet UILabel *competitorNameLabel;
@property IBOutlet UILabel *challengeNameLabel;

- (void)loadWithChallenge:(Challenge*)challenge;

@end
