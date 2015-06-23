//
//  SignUpController.h
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/17/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>

@interface SignUpController : UIViewController <UITextViewDelegate>

@property IBOutlet UIImage *profileImage;
@property IBOutlet UIImageView *profileImageView;
@property IBOutlet UITextField *nickname;
@property IBOutlet UIButton *signUp;

@property IBOutlet UIView *takePhotoBackground;
@property IBOutlet UIView *photoLibraryBackground;
@property IBOutlet UIView *signUpBakcgeound;
@property IBOutlet UIView *facebookSignUpBackground;
@property IBOutlet UIView *nicknameLine;

@end
