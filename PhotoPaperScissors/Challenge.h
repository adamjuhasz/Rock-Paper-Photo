//
//  Challenge.h
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/15/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "ChallengeTheme.h"

typedef enum : NSUInteger {
    Challenger,
    Challengee,
    Unknown
} PlayerType;

typedef enum : NSUInteger {
    myTurn,
    theirTurn,
    noonesTurn
} WhosTurn;

@interface Challenge : NSObject

@property PFObject *parseObject;
@property NSMutableArray *imageRounds;

@property NSUInteger currentRoundNumber;
@property NSUInteger maxRounds;

@property NSString *challengeName;
@property PFUser *challenger;
@property PFUser *challengee;
@property PFUser *otherUser;

@property PlayerType playerIAm;
@property PlayerType otherPlayerIs;

@property BOOL photoSent;
@property BOOL challengeComplete;

@property ChallengeTheme *theme;
@property PFObject *themObject;

@property WhosTurn whosTurn;

- (id)initWithParseObject:(PFObject*)object;
- (void)setImage:(UIImage*)image ForPlayer:(PlayerType)player forRound:(NSUInteger)roundNumber;
- (UIImage*)imageForPlayer:(PlayerType)player forRound:(NSUInteger)roundNumber;
- (void)save;
+ (id)challengeForParseObject:(PFObject*)object;

@end
