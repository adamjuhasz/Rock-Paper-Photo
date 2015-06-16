//
//  FriendCell.h
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/15/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>

@interface FriendCell : PFTableViewCell

@property IBOutlet PFImageView *friendPhoto;
@property IBOutlet UILabel *friendName;

@end
