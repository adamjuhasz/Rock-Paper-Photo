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

@property IBOutlet UIView *takePhotoBackground;
@property IBOutlet UIView *photoLibraryBackground;
@property IBOutlet UIView *linkFacebookBackground;
@property IBOutlet UIView *saveBackground;
@property IBOutlet UIView *tabBarBackground;
@property IBOutlet UIView *nicknameLine;

@property IBOutlet UIButton *saveButton;


@end
