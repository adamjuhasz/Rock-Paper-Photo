//
//  ProfileViewController.h
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/16/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>

@interface ProfileViewController : UIViewController

@property IBOutlet PFImageView *profileImage;
@property IBOutlet UITextField *nickname;
@property UIImage *aNewProfileImage;

@end
