//
//  Challenge.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/15/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "Challenge.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

NSMutableDictionary *cachedChallenges;

@implementation Challenge

+ (id)challengeForParseObject:(PFObject*)object
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cachedChallenges = [NSMutableDictionary dictionary];
    });
    if ([cachedChallenges objectForKey:object.objectId]) {
        return [cachedChallenges objectForKey:object.objectId];
    }
    
    Challenge *newChallenge = [[Challenge alloc] initWithParseObject:object];
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
        self.imageRounds = [NSMutableArray array];
        
        [[RACObserve(self, challenger) filter:^BOOL(id value) {
            return (value != nil);
        }] subscribeNext:^(PFUser *challenger) {
            if ([challenger.objectId isEqualToString:[[PFUser currentUser] objectId]]) {
                self.playerIAm = Challenger;
            }
            self.parseObject[@"createdBy"] = challenger;
            self.parseObject[@"createdById"] = challenger.objectId;
            /*
            [self.parseObject saveEventually:^(BOOL succeeded, NSError *PF_NULLABLE_S error){
                if (error) {
                    return;
                }
            }];
            */
        }];
        
        [[RACObserve(self, challengee) filter:^BOOL(id value) {
            return (value != nil);
        }] subscribeNext:^(PFUser *challengee) {
            if ([challengee.objectId isEqualToString:[[PFUser currentUser] objectId]]) {
                self.playerIAm = Challengee;
            }
            self.parseObject[@"challengee"] = challengee;
            self.parseObject[@"challengeeId"] = challengee.objectId;
            /*
            [self.parseObject saveEventually:^(BOOL succeeded, NSError *PF_NULLABLE_S error){
                if (error) {
                    return;
                }
            }];
            */
        }];
        
        [[RACObserve(self, challengeName) filter:^BOOL(id value) {
            return (value != nil);
        }] subscribeNext:^(NSString *challengeName) {
            self.parseObject[@"challengeName"] = challengeName;
            /*
            [self.parseObject saveEventually:^(BOOL succeeded, NSError *PF_NULLABLE_S error){
                if (error) {
                    return;
                }
            }];
            */
        }];
        
        [[RACObserve(self, currentRoundNumber) filter:^BOOL(id value) {
            return (value != nil);
        }] subscribeNext:^(NSNumber *currentRoundNumber) {
            self.parseObject[@"roundNumber"] = currentRoundNumber;
            /*
            [self.parseObject saveEventually:^(BOOL succeeded, NSError *PF_NULLABLE_S error){
                if (error) {
                    return;
                }
            }];
            */
        }];
    }
    return self;
}

- (id)initWithParseObject:(PFObject*)object
{
    self = [self init];
    if (self) {
        [self.parseObject unpinInBackground];
        self.parseObject = object;
        [object pinInBackgroundWithName:@"Challenge"];
        self.challengeName = object[@"challengeName"];
        self.currentRoundNumber = [object[@"roundNumber"] unsignedIntegerValue];
        self.challengee = object[@"challengee"];
        self.challenger = object[@"createdBy"];
        if ([self.challenger.objectId isEqualToString:[[PFUser currentUser] objectId]]) {
            self.playerIAm = Challenger;
        } else if ([self.challengee.objectId isEqualToString:[[PFUser currentUser] objectId]]) {
            self.playerIAm = Challengee;
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
                        return;
                    }
                    
                    NSLog(@"Downloaded image for Round %d for %@", i+1, @"Challenger");
                    UIImage *image = [UIImage imageWithData:data];
                    [roundDict setObject:image forKey:@"Challenger"];
                }];
            }
            
            PFFile *fileChallengee = object[keyChallengee];
            if (fileChallengee) {
                [fileChallengee getDataInBackgroundWithBlock:^(NSData *PF_NULLABLE_S data, NSError *PF_NULLABLE_S error){
                    if (error) {
                        return;
                    }
                    
                    NSLog(@"Downloaded image for Round %d for %@", i+1, @"Challengee");
                    UIImage *image = [UIImage imageWithData:data];
                    [roundDict setObject:image forKey:@"Challengee"];
                }];
            }
        }
    }
    return self;
}
- (void)setImage:(UIImage*)image ForPlayer:(PlayerType)player forRound:(NSUInteger)roundNumber
{
    for (int i=0; i<roundNumber; i++) {
        if (self.imageRounds.count <= i) {
            NSMutableDictionary *roundDictionary = [NSMutableDictionary dictionary];
            [self.imageRounds addObject:roundDictionary];
        }
    }
    
    NSData *fileData = UIImageJPEGRepresentation(image, 0.9);
    PFFile *file = [PFFile fileWithName:@"image.jpg" data:fileData contentType:@"image/jpeg"];
    
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
    
    [file saveInBackground];
    /*[self.parseObject saveEventually:^(BOOL succeeded, NSError *PF_NULLABLE_S error){
        if (error) {
            return;
        }
    }];*/
}

- (UIImage*)imageForPlayer:(PlayerType)player forRound:(NSUInteger)roundNumber
{
    if (self.imageRounds.count < roundNumber) {
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
    [self.parseObject saveEventually:^(BOOL succeeded, NSError *PF_NULLABLE_S error){
        if (error) {
            return;
        }
        
        [cachedChallenges setObject:self forKey:self.parseObject.objectId];
    }];
}

@end
