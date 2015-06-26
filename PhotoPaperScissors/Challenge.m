//
//  Challenge.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/15/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "Challenge.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "PFAnalytics+PFAnalytics_TrackError.h"

NSMutableDictionary *cachedChallenges;

@implementation Challenge

+ (id)challengeForParseObject:(PFObject*)object
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cachedChallenges = [NSMutableDictionary dictionary];
    });
    
    if (object.objectId == nil) {
        return [[Challenge alloc] initWithParseObject:object];
    }
    
    Challenge *potentialCachedChallenge = [cachedChallenges objectForKey:object.objectId];
    if (potentialCachedChallenge) {
        NSComparisonResult updatedComparison = [potentialCachedChallenge.parseObject.updatedAt compare:object.updatedAt];
        if (updatedComparison != NSOrderedAscending) {
            return [cachedChallenges objectForKey:object.objectId];
        }
    }
    
    Challenge *newChallenge = [[Challenge alloc] initWithParseObject:object];
    if ([cachedChallenges objectForKey:object.objectId]) {
        NSLog(@"replacing challenge with new one");
    }
    [cachedChallenges setObject:newChallenge forKey:object.objectId];
    return newChallenge;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.parseObject = [PFObject objectWithClassName:@"Challenge"];
        [self.parseObject pinInBackgroundWithName:@"Challenge"];
        self.playerIAm = Unknown;
        self.otherPlayerIs = Unknown;
        self.imageRounds = [NSMutableArray array];
        self.photoSent = NO;
        self.challengeComplete = NO;
        
        NSNumber *maxRounds = [[PFConfig currentConfig] objectForKey:@"maxRounds"];
        if (maxRounds == nil) {
            maxRounds = @(3);
        }
        self.maxRounds = [maxRounds unsignedIntegerValue];
        self.parseObject[@"maxRounds"] = maxRounds;
        
        [[RACObserve(self, challenger) filter:^BOOL(id value) {
            return (value != nil);
        }] subscribeNext:^(PFUser *challenger) {
            self.parseObject[@"createdBy"] = challenger;
            self.parseObject[@"createdById"] = challenger.objectId;
            
            if ([challenger.objectId isEqualToString:[[PFUser currentUser] objectId]]) {
                self.playerIAm = Challenger;
                self.otherPlayerIs = Challengee;
                if (self.parseObject[@"challengee"]) {
                    self.competitor = self.parseObject[@"challengee"];
                }
            } else {
                self.competitor = self.parseObject[@"createdBy"];
            }
        }];
        
        [[RACObserve(self, challengee) filter:^BOOL(id value) {
            return (value != nil);
        }] subscribeNext:^(PFUser *challengee) {
            self.parseObject[@"challengee"] = challengee;
            self.parseObject[@"challengeeId"] = challengee.objectId;
            
            if ([challengee.objectId isEqualToString:[[PFUser currentUser] objectId]]) {
                self.playerIAm = Challengee;
                self.otherPlayerIs = Challenger;
                if (self.parseObject[@"createdBy"]) {
                    self.competitor = self.parseObject[@"createdBy"];
                }
            } else {
                self.competitor = self.parseObject[@"challengee"];
            }
        }];
        
        [[RACObserve(self, challengeName) filter:^BOOL(id value) {
            return (value != nil);
        }] subscribeNext:^(NSString *challengeName) {
            self.parseObject[@"challengeName"] = challengeName;
        }];
        
        [[RACObserve(self, currentRoundNumber) filter:^BOOL(id value) {
            return (value != nil);
        }] subscribeNext:^(NSNumber *currentRoundNumber) {
            self.parseObject[@"roundNumber"] = currentRoundNumber;
            if ([self imageForPlayer:self.playerIAm forRound:currentRoundNumber.integerValue] == nil) {
                self.photoSent = NO;
                self.whosTurn = myTurn;
            }
        }];
        
        [[RACObserve(self, challengeComplete) filter:^BOOL(id value) {
            return (value != nil);
        }] subscribeNext:^(NSNumber *isComplete) {
            self.parseObject[@"completed"] = [NSNumber numberWithBool:[isComplete boolValue]];
        }];
        
        [[RACObserve(self, themObject) filter:^BOOL(id value) {
            return (value != nil);
        }] subscribeNext:^(PFObject *theme) {
            self.parseObject[@"theme"] = theme;
        }];
    }
    return self;
}

- (id)initWithParseObject:(PFObject*)object
{
    self = [self init];
    if (self) {
        [self.parseObject unpinInBackground];
        [object pinInBackgroundWithName:@"Challenge"];
        
        _challengeName = object[@"challengeName"];
        _currentRoundNumber = [object[@"roundNumber"] unsignedIntegerValue];
        _maxRounds = [object[@"maxRounds"] unsignedIntegerValue];
        _challengee = object[@"challengee"];
        _challenger = object[@"createdBy"];
        _themObject = object[@"theme"];
        if (self.themObject) {
            self.theme = [[ChallengeTheme alloc] initWithParseObject:self.themObject];
        }
        
        if ([self.challenger.objectId isEqualToString:[[PFUser currentUser] objectId]]) {
            _playerIAm = Challenger;
            _otherPlayerIs = Challengee;
            _competitor = _challengee;
        } else if ([self.challengee.objectId isEqualToString:[[PFUser currentUser] objectId]]) {
            _playerIAm = Challengee;
            _otherPlayerIs = Challenger;
            _competitor = _challenger;
        } else {
            _playerIAm = Unknown;
            _otherPlayerIs = Unknown;
            _photoSent = YES;
        }
        
        for (int i=0; i<self.currentRoundNumber; i++) {
            NSMutableDictionary *roundDict = [NSMutableDictionary dictionary];
            [self.imageRounds addObject:roundDict];
            
            NSString *keyChallenger = [NSString stringWithFormat:@"imageR%d%@", i, @"Challenger"];
            NSString *keyChallengee = [NSString stringWithFormat:@"imageR%d%@", i, @"Challengee"];
            
            PFFile *fileChallenger = object[keyChallenger];
            if (fileChallenger) {
                [fileChallenger getDataInBackgroundWithBlock:^(NSData *PF_NULLABLE_S data, NSError *PF_NULLABLE_S error){
                    if (error) {
                        [PFAnalytics trackErrorIn:NSStringFromSelector(_cmd) withComment:@"getDataInBackgroundWithBlock" withError:error];
                        return;
                    }
                    
                    UIImage *image = [UIImage imageWithData:data];
                    [roundDict setObject:image forKey:@"Challenger"];
                }];
            }
            
            PFFile *fileChallengee = object[keyChallengee];
            if (fileChallengee) {
                [fileChallengee getDataInBackgroundWithBlock:^(NSData *PF_NULLABLE_S data, NSError *PF_NULLABLE_S error){
                    if (error) {
                        [PFAnalytics trackErrorIn:NSStringFromSelector(_cmd) withComment:@"getDataInBackgroundWithBlock" withError:error];
                        return;
                    }
                    
                    UIImage *image = [UIImage imageWithData:data];
                    [roundDict setObject:image forKey:@"Challengee"];
                }];
            }
            
            if ((self.currentRoundNumber - 1) == i) {
                //current round
                _whosTurn = noonesTurn;
                
                if (self.playerIAm == Challenger) {
                    if (fileChallenger) {
                        _photoSent = YES;
                        if (fileChallengee == nil) {
                            _whosTurn = theirTurn;
                        }
                    } else {
                        _whosTurn = myTurn;
                    }
                }
                
                if (self.playerIAm == Challengee) {
                    if (fileChallengee) {
                        _photoSent = YES;
                        if (fileChallenger == nil) {
                            _whosTurn = theirTurn;
                        }
                    } else {
                        _whosTurn = myTurn;
                    }
                }
            }
            
            _challengeComplete = [object[@"completed"] boolValue];
            if (_challengeComplete) {
                _whosTurn = noonesTurn;
            }
        }
        _parseObject = object;
    }
    return self;
}

- (void)setImage:(UIImage*)image ForPlayer:(PlayerType)player forRound:(NSUInteger)roundNumber
{
    if (player == Unknown) {
        return;
    }
    
    if (roundNumber > self.maxRounds) {
        return;
    }
    
    for (int i=0; i<roundNumber; i++) {
        if (self.imageRounds.count <= i) {
            NSMutableDictionary *roundDictionary = [NSMutableDictionary dictionary];
            [self.imageRounds addObject:roundDictionary];
        }
    }
    
    NSData *fileData = UIImageJPEGRepresentation(image, 0.9);
    PFFile *file = [PFFile fileWithName:@"image.jpg" data:fileData contentType:@"image/jpeg"];
    [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *PF_NULLABLE_S error){
        if (error) {
            [PFAnalytics trackErrorIn:NSStringFromSelector(_cmd) withComment:@"saveInBackgroundWithBlock" withError:error];
            return;
        }
        
        NSLog(@"File for round %ld uploaded", roundNumber);
    }];
    
    NSMutableDictionary *roundDictionary = [self.imageRounds objectAtIndex:roundNumber-1];
    switch (player) {
        case Challenger:
        {
            [roundDictionary setObject:image forKey:@"Challenger"];
            NSString *keyChallenger = [NSString stringWithFormat:@"imageR%lu%@", (unsigned long)roundNumber-1, @"Challenger"];

            self.parseObject[keyChallenger] = file;
        }
            break;
            
        case Challengee:
        {
            [roundDictionary setObject:image forKey:@"Challengee"];
            NSString *keyChallengee = [NSString stringWithFormat:@"imageR%lu%@", (unsigned long)roundNumber-1, @"Challengee"];
            self.parseObject[keyChallengee] = file;
        }
            break;
            
        default:
            break;
    }
    
    
    if (self.otherPlayerIs == Challengee && [roundDictionary objectForKey:@"Challengee"]) {
        self.whosTurn = noonesTurn;
    } else {
        self.whosTurn = theirTurn;
    }
    
    if (self.otherPlayerIs == Challenger && [roundDictionary objectForKey:@"Challenger"]) {
        self.whosTurn = noonesTurn;
    } else {
        self.whosTurn = theirTurn;
    }
    
    [file saveInBackground];
}

- (UIImage*)imageForPlayer:(PlayerType)player forRound:(NSUInteger)roundNumber
{
    if (player == Unknown) {
        return nil;
    }
    
    if (roundNumber > self.maxRounds) {
        return nil;
    }
    
    if (self.imageRounds.count == 0) {
        return nil;
    }
    
    if (self.imageRounds.count < roundNumber) {
        return nil;
    }
    
    if (roundNumber == 0) {
        return nil;
    }

    
    NSDictionary *roundImages = [self.imageRounds objectAtIndex:roundNumber-1];
    switch (player) {
        case Challenger:
            return [roundImages objectForKey:@"Challenger"];
            break;
            
        case Challengee:
            return [roundImages objectForKey:@"Challengee"];
            break;
            
        default:
            break;
    }
    
    return nil;
}

- (void)save
{
    if ([self imageForPlayer:self.playerIAm forRound:self.currentRoundNumber]) {
        self.photoSent = YES;
    }
    
    if ([self imageForPlayer:self.playerIAm forRound:self.currentRoundNumber] &&
        [self imageForPlayer:self.otherPlayerIs forRound:self.currentRoundNumber] &&
        (self.currentRoundNumber+1 <= self.maxRounds)) {
            self.whosTurn = myTurn;
    }
    
    if (self.currentRoundNumber == self.maxRounds) {
        UIImage *currentChallengerImage = [self imageForPlayer:Challenger forRound:self.currentRoundNumber];
        UIImage *currentChallengeeImage = [self imageForPlayer:Challengee forRound:self.currentRoundNumber];
        if (currentChallengerImage && currentChallengeeImage) {
            self.challengeComplete = YES;
            self.whosTurn = noonesTurn;
        }
    }
    
    if (self.currentRoundNumber > self.maxRounds) {
        self.challengeComplete = YES;
        self.whosTurn = noonesTurn;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateChallanges" object:nil];
    
    [self.parseObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *PF_NULLABLE_S error){
        if (error){
            [PFAnalytics trackErrorIn:NSStringFromSelector(_cmd) withComment:@"saveInBackgroundWithBlock" withError:error];
            return;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updateChallanges" object:nil];
        
        //PUSH
        PFUser *otherUser = self.competitor;
        if ([otherUser.objectId isEqualToString:[[PFUser currentUser] objectId]]) {
            
        }
        PFQuery *userQuery = [PFInstallation query];
        [userQuery whereKey:@"user" equalTo:otherUser];
        
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        [data setObject:@"A new round has started" forKey:@"alert"];
        [data setObject:@"Increment" forKey:@"badge"];
        
        if (self.currentRoundNumber == 1 && self.playerIAm == Challenger) {
            [data setObject:@"You've been challanged!" forKey:@"alert"];
        }
        if (self.currentRoundNumber == self.maxRounds && [self imageForPlayer:self.otherPlayerIs forRound:self.currentRoundNumber]) {
            [data setObject:@"Challenge complete!" forKey:@"alert"];
        }
        PFPush *push = [[PFPush alloc] init];
        [push setData:data];
        [push setQuery:userQuery];
        [push sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError * __nullable error) {
            if (error) {
                NSLog(@"Error with push: %@", error);
                [PFAnalytics trackErrorIn:NSStringFromSelector(_cmd) withComment:@"sendPushInBackgroundWithBlock" withError:error];
                return;
            }
        }];
    }];
}

@end
