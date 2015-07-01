//
//  FriendCollectionCell.h
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/20/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "PFCollectionViewCell.h"
#import <ParseUI/ParseUI.h>

@interface FriendCollectionCell : PFCollectionViewCell

@property IBOutlet PFImageView *profileImageView;
@property IBOutlet UITextField *nickname;

@end
