//
//  SignUpController.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/17/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "SignUpController.h"

#import <NYXImagesKit/NYXImagesKit.h>
#import <Parse/Parse.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <NSURLConnection-Blocks/NSURLConnection+Blocks.h>
#import <Flow/Flow.h>
#import <UICKeyChainStore/UICKeyChainStore.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <Colours/Colours.h>

#import "PFAnalytics+PFAnalytics_TrackError.h"
#import "UIImage+fixOrientation.h"

static NSString * const SignUpNicknameTutorialString = @"io.ajuhasz.signup.nickname";
static NSString * const SignUpPhotoTutorialString = @"io.ajuhasz.signup.photo";
static NSString * const SignUpCompleteTutorialString = @"io.ajuhasz.signup.complete";

@interface SignUpController () <UITextFieldDelegate>

@property BOOL isLoggedIn;
@property BOOL newUser;

@end

@implementation SignUpController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.signUp.enabled = NO;
    self.profileImageView.clipsToBounds = YES;
    self.profileImageView.layer.cornerRadius = self.profileImageView.bounds.size.width/2.0;
    self.isLoggedIn = NO;
    self.newUser = YES;

    CGFloat increaseRatio = 0.15;
    UIColor *baseColor = [UIColor colorFromHexString:@"#6F70FF"];
    self.view.backgroundColor = baseColor;
    self.takePhotoBackground.backgroundColor = [baseColor darken:increaseRatio * 1];
    self.photoLibraryBackground.backgroundColor = [baseColor darken:increaseRatio * 2];
    self.signUpBakcgeound.backgroundColor = [baseColor darken:increaseRatio * 3];
    self.facebookSignUpBackground.backgroundColor = [baseColor darken:increaseRatio * 4];
    self.nicknameLine.backgroundColor = [baseColor blackOrWhiteContrastingColor];
    self.nickname.textColor = [baseColor blackOrWhiteContrastingColor];
    
    RAC(self.profileImageView, image) = [RACObserve(self, profileImage) filter:^BOOL(id value) {
        return (value != nil);
    }];
    
    RACSignal *validNickname = [self.nickname.rac_textSignal map:^id(NSString *text) {
         return @(text.length > 0);
     }];
    
    RACSignal *validPhoto = [RACObserve(self, profileImage) map:^id(UIImage *image) {
        return @(image != nil);
    }];
    
    RACSignal *validSignup = [RACObserve(self, isLoggedIn) map:^id(NSNumber *loggedIn) {
        return loggedIn;
    }];
    
    RACSignal *signUpActiveSignal = [RACSignal combineLatest:@[validNickname, validPhoto]
                      reduce:^id(NSNumber *usernameValid, NSNumber *photoValid) {
                          return @([usernameValid boolValue] && [photoValid boolValue]);
                      }];
    
    RACSignal *dismissSignal = [RACSignal combineLatest:@[validNickname, validPhoto, validSignup]
                                                      reduce:^id(NSNumber *usernameValid, NSNumber *photoValid, NSNumber *loggedIn) {
                                                          return @([usernameValid boolValue] && [photoValid boolValue] && [loggedIn boolValue]);
                                                      }];

    self.nickname.delegate = self;
    
    [signUpActiveSignal subscribeNext:^(NSNumber *signupActive) {
        BOOL isActive = [signupActive boolValue];
        self.signUp.enabled = isActive;
        if (isActive) {
            [self.signUp setTitleColor:[UIColor colorWithWhite:1.0 alpha:1.0] forState:UIControlStateNormal];
        } else {
            [self.signUp setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.5] forState:UIControlStateNormal];
        }
        
    }];
    
    [dismissSignal subscribeNext:^(NSNumber *readyToDismiss) {
        if ([readyToDismiss boolValue]) {
            //
        }
    }];
    
    [[FLWTutorialController sharedInstance] resetTutorialWithIdentifier:SignUpNicknameTutorialString];
    [[FLWTutorialController sharedInstance] resetTutorialWithIdentifier:SignUpPhotoTutorialString];
    [[FLWTutorialController sharedInstance] resetTutorialWithIdentifier:SignUpCompleteTutorialString];
    
    __weak typeof(self) weakSelf = self;
    [[FLWTutorialController sharedInstance] scheduleTutorialWithIdentifier:SignUpNicknameTutorialString
                                                                afterDelay:2.0
                                                             withPredicate:^BOOL{
                                                                 __strong typeof(self) strongSelf = weakSelf;
                                                                 return strongSelf.nickname.text.length == 0;
                                                             }
                                                         constructionBlock:^(id<FLWTutorial> tutorial) {
                                                             tutorial.title = @"Welcome to Rock Paper Photo!\nTo start please choose a nickname.";
                                                             tutorial.successMessage = @"That's a great name";
                                                             tutorial.speechSynthesisesDisabled = NO;
    }];
    
    [[FLWTutorialController sharedInstance] scheduleTutorialWithIdentifier:SignUpPhotoTutorialString
                                                                afterDelay:2.0
                                                             withPredicate:NULL
                                                         constructionBlock:^(id<FLWTutorial> tutorial) {
                                                             tutorial.title = @"Now let's pick a photo from your library or take a new photo.";
                                                             tutorial.successMessage = @"You look great.";
                                                             tutorial.speechSynthesisesDisabled = NO;
                                                             tutorial.dependentTutorialIdentifiers = @[SignUpNicknameTutorialString];
                                                         }];
    
    [[FLWTutorialController sharedInstance] scheduleTutorialWithIdentifier:SignUpCompleteTutorialString
                                                                afterDelay:2.0
                                                             withPredicate:NULL
                                                         constructionBlock:^(id<FLWTutorial> tutorial) {
                                                             tutorial.title = @"You're all done!\nIf you're ready, click sign up.";
                                                             tutorial.speechSynthesisesDisabled = NO;
                                                             tutorial.dependentTutorialIdentifiers = @[SignUpNicknameTutorialString, SignUpPhotoTutorialString];
                                                         }];

}

- (IBAction)signUp:(id)sender
{
    [FBSDKAppEvents logEvent:@"SignUpStart"];
    PFUser *user = [PFUser user];
    user.username = [self randomStringWithLength:30];
    user.password = [self randomStringWithLength:20];
    PFFile *file = [PFFile fileWithName:@"profile.jpg" data:UIImageJPEGRepresentation(self.profileImage, 0.9)];
    user[@"image"] = file;
    user[@"nickname"] = self.nickname.text;
    
    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            NSLog(@"%@", error);
            [PFAnalytics trackErrorIn:NSStringFromSelector(_cmd) withComment:@"signUpInBackgroundWithBlock" withError:error];
            return;
        }
        self.isLoggedIn = YES;
        
<<<<<<< HEAD
        [FBSDKAppEvents logEvent:FBSDKAppEventNameCompletedRegistration
                      parameters:[NSDictionary dictionaryWithObject:@"RPP" forKey:FBSDKAppEventParameterNameRegistrationMethod]];
=======
        UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:@"iCloud.io.ajuhasz.rpp.icloud"];
        keychain.synchronizable = YES;
        keychain[@"username"] = user.username;
        keychain[@"password"] = user.password;

>>>>>>> collection
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

-(NSString *) randomStringWithLength: (int) len {
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    [randomString appendString:@"Gen"];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((unsigned int)[letters length])]];
    }
    
    return randomString;
}
    
- (IBAction)signUpWithFaceBook:(id)sender
{
    self.nickname.userInteractionEnabled = NO;
    self.profileImageView.userInteractionEnabled = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(facebookProfileUpdated) name:FBSDKProfileDidChangeNotification object:nil];
    
    NSArray *permissions = @[@"public_profile", @"user_friends"];
    
    [PFFacebookUtils logInInBackgroundWithReadPermissions:permissions block:^(PFUser *user, NSError *error) {
        if (error) {
            [PFAnalytics trackErrorIn:NSStringFromSelector(_cmd) withComment:@"logInInBackgroundWithReadPermissions" withError:error];
            return;
        }
        
        if (!user) {
            NSLog(@"Uh oh. The user cancelled the Facebook login.");
            self.nickname.userInteractionEnabled = YES;
            self.profileImageView.userInteractionEnabled = YES;
            return;
        }
        
        [[FLWTutorialController sharedInstance] completeTutorialWithIdentifier:SignUpNicknameTutorialString];
        [[FLWTutorialController sharedInstance] completeTutorialWithIdentifier:SignUpPhotoTutorialString];
        [[FLWTutorialController sharedInstance] completeTutorialWithIdentifier:SignUpCompleteTutorialString];
        
        if (user.isNew) {
            NSLog(@"User signed up and logged in through Facebook!");
            PFUser *current = [PFUser currentUser];
            if (current) {
                if (self.nickname.text) {
                    current[@"nickname"] = self.nickname.text;
                }
                if (self.profileImage) {
                    PFFile *file = [PFFile fileWithName:@"profile.jpg" data:UIImageJPEGRepresentation(self.profileImage, 0.9)];
                    current[@"image"] = file;
                }
                [current saveInBackground];
            }
            UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:@"iCloud.io.ajuhasz.rpp.icloud"];
            keychain.synchronizable = YES;
            keychain[@"username"] = user.username;
            keychain[@"password"] = user.password;
            
            if (self.nickname.text.length > 0 && self.profileImage != nil) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        } else {
            self.newUser = NO;
            NSLog(@"User logged in through Facebook!");
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        
        self.isLoggedIn = YES;
    }];
}

- (IBAction)getNewImage:(id)sender
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.delegate = (id)self;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (IBAction)getNewPhoto:(id)sender
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO) {
        return;
    }
    
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
        imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    }
    
    imagePickerController.delegate = (id)self;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //You can retrieve the actual UIImage
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    UIImage *rotated = [image fixOrientation];
    UIImage *scaled = [rotated scaleToSize:CGSizeMake(300, 300) usingMode:NYXResizeModeAspectFill];
    UIImage *cropped = [scaled cropToSize:CGSizeMake(300, 300) usingMode:NYXCropModeBottomCenter];
    UIImage *normalized = cropped;
    self.profileImage = normalized;
    
    [picker dismissViewControllerAnimated:YES completion:^{
        [[FLWTutorialController sharedInstance] completeTutorialWithIdentifier:SignUpPhotoTutorialString];
    }];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [[FLWTutorialController sharedInstance] completeTutorialWithIdentifier:SignUpNicknameTutorialString];
}

#pragma mark FaceBook signup stuff

- (void)facebookProfileUpdated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FBSDKProfileDidChangeNotification object:nil];
    
    FBSDKProfile *currentFBProfile = [FBSDKProfile currentProfile];
    
    if (self.nickname.text.length == 0) {
        if ([PFUser currentUser]) {
            [[PFUser currentUser] setObject:currentFBProfile.name forKey:@"nickname"];
        }
        self.nickname.text = currentFBProfile.name;
    }
    
    if (self.profileImage == nil) {
        NSString *imagePath = [currentFBProfile imagePathForPictureMode:FBSDKProfilePictureModeSquare size:CGSizeMake(300, 300)];
        NSURL *imageUrl = [NSURL URLWithString:imagePath relativeToURL:[NSURL URLWithString:@"http://graph.facebook.com/"]];
        NSURLRequest *imageRequst = [NSURLRequest requestWithURL:imageUrl];
        [NSURLConnection connectionWithRequest:imageRequst
                                  onCompletion:^(NSData *data, NSInteger statusCode) {
                                      UIImage *profile = [UIImage imageWithData:data];
                                      if ([PFUser currentUser] && self.newUser) {
                                          PFFile *file = [PFFile fileWithName:@"profile.jpg" data:UIImageJPEGRepresentation(profile, 0.9)];
                                          [[PFUser currentUser] setObject:file forKey:@"image"];
                                      }
                                      self.profileImage = profile;
                                  }
                                        onFail:^(NSError *error, NSInteger statusCode) {
                                            [PFAnalytics trackErrorIn:NSStringFromSelector(_cmd)
                                                          withComment:@"connectionWithRequest"
                                                            withError:error];
                                        }];
    }
}


@end
