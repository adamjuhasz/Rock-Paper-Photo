//
//  CameraController.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/15/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "CameraController.h"
#import <FastttCamera/FastttCamera.h>
#import "PhotoViewController.h"

@interface CameraController () <FastttCameraDelegate>

@property FastttCamera *fastCamera;

@end

@implementation CameraController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _fastCamera = [FastttCamera new];
    self.fastCamera.delegate = self;
    
    [self fastttAddChildViewController:self.fastCamera];
    self.fastCamera.view.frame = self.cameraContainer.frame;
    
    self.shutterButton.center = CGPointMake(self.view.bounds.size.width/2.0, (self.view.bounds.size.height - CGRectGetMaxY(self.fastCamera.view.frame)) / 2.0 + CGRectGetMaxY(self.fastCamera.view.frame));
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    //self.navigationController.navigationBar.barTintColor = [UIColor blackColor];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    self.tabBarController.tabBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.tabBarController.tabBar.hidden = NO;
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
}

- (IBAction)switchCamera
{

    switch (self.fastCamera.cameraDevice) {
        case FastttCameraDeviceFront:
            if ([FastttCamera isCameraDeviceAvailable:FastttCameraDeviceRear]) {
                [self.fastCamera setCameraDevice:FastttCameraDeviceRear];
            }
            break;
            
        case FastttCameraDeviceRear:
            if ([FastttCamera isCameraDeviceAvailable:FastttCameraDeviceFront]) {
                [self.fastCamera setCameraDevice:FastttCameraDeviceFront];
            }
            break;
    }
    
}

- (IBAction)switchFlash:(id)sender
{
    
    switch (self.fastCamera.cameraFlashMode) {
        case FastttCameraFlashModeAuto:
            if ([FastttCamera isFlashAvailableForCameraDevice:self.fastCamera.cameraDevice]) {
                [self.fastCamera setCameraFlashMode:FastttCameraFlashModeOn];
                [self.flashButton setTitle:@"Flash On" forState:UIControlStateNormal];
            }
            break;
            
        case FastttCameraFlashModeOn:
            if ([FastttCamera isFlashAvailableForCameraDevice:self.fastCamera.cameraDevice]) {
                [self.fastCamera setCameraFlashMode:FastttCameraFlashModeOff];
                [self.flashButton setTitle:@"Flash Off" forState:UIControlStateNormal];
            }
            break;
            
        case FastttCameraFlashModeOff:
            if ([FastttCamera isFlashAvailableForCameraDevice:self.fastCamera.cameraDevice]) {
                [self.fastCamera setCameraFlashMode:FastttCameraFlashModeAuto];
                [self.flashButton setTitle:@"Flash Auto" forState:UIControlStateNormal];
            }
            break;
    }
}

- (IBAction)shutter:(id)sender
{
    [self.fastCamera takePicture];
}

- (void)cameraController:(id<FastttCameraInterface>)cameraController didFinishNormalizingCapturedImage:(FastttCapturedImage *)capturedImage
{
    self.takenPhoto = capturedImage.scaledImage;
    [self.theChallenge setImage:self.takenPhoto ForPlayer:self.theChallenge.playerIAm forRound:self.theChallenge.currentRoundNumber];
    [self performSegueWithIdentifier:@"showPhotos" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showPhotos"]) {
        PhotoViewController *photoViewer = (PhotoViewController*)segue.destinationViewController;
        photoViewer.theChallenge = self.theChallenge;
    }
}

@end
