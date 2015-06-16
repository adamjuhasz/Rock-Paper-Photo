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

typedef enum : NSUInteger {
    Challenger,
    Challengee,
    Unknown
} PlayerType;

@interface Challenge : NSObject

@property PFObject *parseObject;
@property NSMutableArray *imageRounds;

@property NSUInteger currentRoundNumber;
@property NSString *challengeName;
@property PFUser *challenger;
@property PFUser *challengee;

@property PlayerType playerIAm;

- (id)initWithParseObject:(PFObject*)object;
- (void)setImage:(UIImage*)image ForPlayer:(PlayerType)player forRound:(NSUInteger)roundNumber;
- (UIImage*)imageForPlayer:(PlayerType)player forRound:(NSUInteger)roundNumber;
- (void)save;
+ (id)challengeForParseObject:(PFObject*)object;

@end