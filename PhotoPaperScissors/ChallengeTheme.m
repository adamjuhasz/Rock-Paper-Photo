//
//  ChallengeTheme.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/18/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "ChallengeTheme.h"

NSMutableDictionary *cachedChallengeThemes;

@implementation ChallengeTheme

+ (id)challengeThemeForParseObject:(PFObject*)object
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cachedChallengeThemes = [NSMutableDictionary dictionary];
    });
    ChallengeTheme *potentialCachedChallengeTheme = [cachedChallengeThemes objectForKey:object.objectId];
    if (potentialCachedChallengeTheme) {
        NSComparisonResult updatedComparison = [potentialCachedChallengeTheme.parseObject.updatedAt compare:object.updatedAt];
        if (updatedComparison != NSOrderedAscending) {
            return [cachedChallengeThemes objectForKey:object.objectId];
        }
    }
    
    ChallengeTheme *newChallengeTheme = [[ChallengeTheme alloc] initWithParseObject:object];
    if ([cachedChallengeThemes objectForKey:object.objectId]) {
        NSLog(@"replacing challenge with new one");
    }
    [cachedChallengeThemes setObject:newChallengeTheme forKey:object.objectId];
    return newChallengeTheme;
}

- (id)initWithParseObject:(PFObject*)object
{
    self = [self init];
    if (self) {
        _parseObject = object;
        
        self.name = object[@"Text"];
        
        self.coverphotoFile = object[@"coverPhoto"];
        self.thumbnailFile = object[@"thumbnail"];
        self.template1File = object[@"template1"];
        self.template2File = object[@"template2"];
        self.template3File = object[@"template3"];
        
        [self.coverphotoFile getDataInBackgroundWithBlock:^(NSData *PF_NULLABLE_S data, NSError *PF_NULLABLE_S error){
            if ((error)) {
                return;
            }
            self.coverphoto = [UIImage imageWithData:data];
        }];
        [self.thumbnailFile getDataInBackgroundWithBlock:^(NSData *PF_NULLABLE_S data, NSError *PF_NULLABLE_S error){
            if ((error)) {
                return;
            }
            self.thumbnail = [UIImage imageWithData:data];
        }];
        [self.template1File getDataInBackgroundWithBlock:^(NSData *PF_NULLABLE_S data, NSError *PF_NULLABLE_S error){
            if ((error)) {
                return;
            }
            self.template1 = [UIImage imageWithData:data];
        }];
        [self.template2File getDataInBackgroundWithBlock:^(NSData *PF_NULLABLE_S data, NSError *PF_NULLABLE_S error){
            if ((error)) {
                return;
            }
            self.template2 = [UIImage imageWithData:data];
        }];
        [self.template3File getDataInBackgroundWithBlock:^(NSData *PF_NULLABLE_S data, NSError *PF_NULLABLE_S error){
            if ((error)) {
                return;
            }
            self.template3 = [UIImage imageWithData:data];
        }];
    }
    return self;
}

@end
