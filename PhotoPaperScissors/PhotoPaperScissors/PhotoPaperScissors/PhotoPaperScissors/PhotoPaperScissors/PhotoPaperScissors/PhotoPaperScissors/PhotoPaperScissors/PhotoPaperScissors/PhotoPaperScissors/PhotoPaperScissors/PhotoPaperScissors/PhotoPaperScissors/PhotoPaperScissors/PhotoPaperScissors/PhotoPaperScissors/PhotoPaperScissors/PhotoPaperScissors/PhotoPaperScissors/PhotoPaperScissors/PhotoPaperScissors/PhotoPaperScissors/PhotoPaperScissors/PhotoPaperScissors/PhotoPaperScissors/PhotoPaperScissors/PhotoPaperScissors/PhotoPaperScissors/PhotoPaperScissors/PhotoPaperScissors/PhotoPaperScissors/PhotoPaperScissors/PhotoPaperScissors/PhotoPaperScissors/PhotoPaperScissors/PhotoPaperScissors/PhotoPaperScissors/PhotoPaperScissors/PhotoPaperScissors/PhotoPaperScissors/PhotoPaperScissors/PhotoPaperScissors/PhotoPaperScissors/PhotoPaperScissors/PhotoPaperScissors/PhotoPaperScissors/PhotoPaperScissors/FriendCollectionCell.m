//
//  FriendCollectionCell.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/20/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "FriendCollectionCell.h"

@implementation FriendCollectionCell

- (void)awakeFromNib
{
    [self commonInit];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.profileImageView.layer.cornerRadius = self.profileImageView.bounds.size.width/2.0;
}

- (void)commonInit
{
    self.profileImageView.layer.cornerRadius = self.profileImageView.bounds.size.width/2.0;
    self.profileImageView.clipsToBounds = YES;
}

- (void)prepareForReuse
{
    self.profileImageView.image = nil;
    self.nickname.text = @"";
}

@end
