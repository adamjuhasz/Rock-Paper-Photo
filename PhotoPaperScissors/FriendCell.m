//
//  FriendCell.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/15/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "FriendCell.h"

@implementation FriendCell

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.friendPhoto.image = nil;
    self.friendPhoto.file = nil;
    self.friendName.text = @"";
}

@end
