//
//  ProfileViewController.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/16/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "ProfileViewController.h"

#import <NYXImagesKit/UIImage+Resizing.h>
#import <Parse/Parse.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <Colours/Colours.h>

#import "UIImage+fixOrientation.h"
#import "PFAnalytics+PFAnalytics_TrackError.h"
#import "PFUser+findFacebookFriends.h"

@interface ProfileViewController () <UIImagePickerControllerDelegate>

@end

@implementation ProfileViewController

- (void)viewDidLoad
{
    self.profileImage.contentMode = UIViewContentModeScaleAspectFill;
    self.profileImage.layer.cornerRadius = self.profileImage.bounds.size.width/2.0;
    self.profileImage.clipsToBounds = YES;
    
    
    RACSignal *validNickname = [self.nickname.rac_textSignal map:^id(NSString *text) {
        return @(text.length > 0);
    }];
    
    [validNickname subscribeNext:^(NSNumber *signupActive) {
        BOOL isActive = [signupActive boolValue];
        self.saveButton.enabled = isActive;
        if (isActive) {
            [self.saveButton setTitleColor:[UIColor colorWithWhite:1.0 alpha:1.0] forState:UIControlStateNormal];
        } else {
            [self.saveButton setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.5] forState:UIControlStateNormal];
        }
        
    }];

    CGFloat increaseRatio = 0.15;
    UIColor *baseColor = [UIColor colorFromHexString:@"#6F70FF"];
    self.view.backgroundColor = baseColor;
    self.takePhotoBackground.backgroundColor = [baseColor darken:increaseRatio * 1];
    self.photoLibraryBackground.backgroundColor = [baseColor darken:increaseRatio * 2];
    self.linkFacebookBackground.backgroundColor = [baseColor darken:increaseRatio * 3];
    self.saveBackground.backgroundColor = [baseColor darken:increaseRatio * 4];
    self.nicknameLine.backgroundColor = [UIColor whiteColor];
    self.nickname.textColor = [UIColor whiteColor];
    
    RAC(self.tabBarBackground,backgroundColor) = RACObserve(self.saveBackground, backgroundColor);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    PFUser *currentUser = [PFUser currentUser];
    self.profileImage.file = currentUser[@"image"];
    [self.profileImage loadInBackground];
    self.nickname.text = currentUser[@"nickname"];
}

- (IBAction)linkToFB
{
    [PFUser findFacebookFriends];
}


- (IBAction)save:(id)sender
{
    PFUser *currentUser = [PFUser currentUser];
    currentUser[@"nickname"] = self.nickname.text;
    if (self.aNewProfileImage) {
        PFFile *file = [PFFile fileWithName:@"profile.jpg" data:UIImageJPEGRepresentation(self.aNewProfileImage, 0.9)];
        currentUser[@"image"] = file;
    }
    [currentUser saveInBackground];
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
    self.profileImage.image = normalized;
    self.aNewProfileImage = normalized;
    
    [picker dismissViewControllerAnimated:YES completion:^{
        
    }];
}

@end
