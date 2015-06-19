//
//  CameraController.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/15/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "CameraController.h"
#import <FastttCamera/FastttCamera.h>
#import <jot/jot.h>
#import "PhotoViewController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ParseUI/ParseUI.h>
#import <NYXImagesKit/NYXImagesKit.h>

@interface CameraController () <FastttCameraDelegate, JotViewControllerDelegate>

@property FastttCamera *fastCamera;
@property JotViewController *jotViewController;
@property UIImageView *imagePreview;
@property PFImageView *templateImageView;
@end

@implementation CameraController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _fastCamera = [FastttCamera new];
    self.fastCamera.delegate = self;
    
    [self fastttAddChildViewController:self.fastCamera];
    [self.fastCamera.view removeFromSuperview];
    [self.cameraContainer addSubview:self.fastCamera.view];
    self.fastCamera.view.frame = self.cameraContainer.bounds;
    if ([FastttCamera isCameraDeviceAvailable:FastttCameraDeviceFront]) {
        self.fastCamera.cameraDevice = FastttCameraDeviceFront;
    }
    
    self.imagePreview = [[UIImageView alloc] initWithFrame:self.cameraContainer.frame];
    self.imagePreview.backgroundColor = [UIColor clearColor];
    [self.cameraContainer insertSubview:self.imagePreview aboveSubview:self.fastCamera.view];
    
    self.templateImageView = [[PFImageView alloc] initWithFrame:self.cameraContainer.frame];
    [self.cameraContainer insertSubview:self.templateImageView aboveSubview:self.imagePreview];
    
    _jotViewController = [JotViewController new];
    self.jotViewController.delegate = self;
    self.jotViewController.state = JotViewStateDrawing;
    self.jotViewController.drawingColor = self.blackColorSwatch.backgroundColor;
    self.jotViewController.textColor = self.blackColorSwatch.backgroundColor;
    
    [self addChildViewController:self.jotViewController];
    self.jotViewController.view.frame = self.cameraContainer.bounds;
    [self.view insertSubview:self.jotViewController.view aboveSubview:self.cameraContainer];
    [self.jotViewController didMoveToParentViewController:self];
    self.jotViewController.view.userInteractionEnabled = NO;
    
    RAC(self.imagePreview, image) = RACObserve(self, takenPhoto);
    [[RACObserve(self, theChallenge) filter:^BOOL(id value) {
         return (value != nil);
     }] subscribeNext:^(Challenge *newChallenge) {
         PFFile *templateFile = nil;
         if (newChallenge.currentRoundNumber == 1) {
             if (newChallenge.theme.template1File) {
                 templateFile = newChallenge.theme.template1File;
             }
         } else if (newChallenge.currentRoundNumber == 2) {
             if (newChallenge.theme.template2File) {
                 templateFile = newChallenge.theme.template2File;
             }
         } else if (newChallenge.currentRoundNumber == 3) {
             if (newChallenge.theme.template3File) {
                 templateFile = newChallenge.theme.template3File;
             }
         }
         if (templateFile) {
             self.templateImageView.file = templateFile;
             [self.templateImageView loadInBackground];
         }
     }];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@" "
                                                                             style:self.navigationItem.backBarButtonItem.style
                                                                            target:nil
                                                                            action:nil];
    self.blackColorSwatch.layer.affineTransform = CGAffineTransformScale(CGAffineTransformIdentity, 0.8, 0.8);
}

- (void)viewWillLayoutSubviews
{
    self.imagePreview.frame = self.cameraContainer.bounds;
    self.templateImageView.frame = self.cameraContainer.bounds;
    self.jotViewController.view.frame = self.cameraContainer.frame;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    //self.navigationController.navigationBar.barTintColor = [UIColor blackColor];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.tabBarController.tabBar.hidden = YES;
    self.title = self.theChallenge.challengeName;
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
    if (self.takenPhoto) {
        self.takenPhoto = nil;
        self.jotViewController.view.userInteractionEnabled = NO;
        [self.jotViewController clearAll];
        self.navigationItem.rightBarButtonItem = nil;
    } else {
        [self.fastCamera takePicture];
    }
}

- (void)cameraController:(id<FastttCameraInterface>)cameraController didFinishNormalizingCapturedImage:(FastttCapturedImage *)capturedImage
{
    self.takenPhoto = capturedImage.scaledImage;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Shoot"
                                                                              style:self.editButtonItem.style
                                                                             target:self
                                                                             action:@selector(sendToServer)];
    self.jotViewController.state = JotViewStateDrawing;
    self.jotViewController.view.userInteractionEnabled = YES;
}

- (void)sendToServer
{
    UIImage *templated = [self.cameraContainer imageByRenderingView];
    UIImage *drawnOnImage = [self.jotViewController drawOnImage:templated];
    [self.theChallenge setImage:drawnOnImage ForPlayer:self.theChallenge.playerIAm forRound:self.theChallenge.currentRoundNumber];
    [self.theChallenge save];
    
    [self performSegueWithIdentifier:@"showPhotos" sender:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateChallanges" object:self.theChallenge];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showPhotos"]) {
        PhotoViewController *photoViewer = (PhotoViewController*)segue.destinationViewController;
        photoViewer.theChallenge = self.theChallenge;
    }
}

- (IBAction)changeDrawColorToBackgroundOf:(id)sender
{
    UIColor *colorToBe = nil;
    UIView *viewToScale = nil;
    
    if ([sender isKindOfClass:[UIView class]]) {
        UIView *sending = (UIView*)sender;
        colorToBe = sending.backgroundColor;
        viewToScale = sender;
    }
    
    if ([sender isKindOfClass:[UITapGestureRecognizer class]]) {
        UIGestureRecognizer *recognizer = (UIGestureRecognizer*)sender;
        UIView *sending = recognizer.view;
        colorToBe = sending.backgroundColor;
        viewToScale = sending;
    }
    
    if (colorToBe == nil)
        return;
    
    for (UIView *view in self.colorSelectors) {
        view.layer.affineTransform = CGAffineTransformIdentity;
    }
    
    viewToScale.layer.affineTransform = CGAffineTransformScale(CGAffineTransformIdentity, 0.8, 0.8);
    
    switch (self.jotViewController.state) {
        case JotViewStateDrawing:
            self.jotViewController.drawingColor = colorToBe;
            break;
            
        case JotViewStateDefault:
        case JotViewStateEditingText:
        case JotViewStateText:
            self.jotViewController.textColor = colorToBe;
            break;
    }
}

- (IBAction)switchToDrawing:(id)sender
{
    self.jotViewController.state = JotViewStateDrawing;
}

- (IBAction)switchToTexting:(id)sender
{
    self.jotViewController.state = JotViewStateEditingText;
}

- (IBAction)clearDrawing:(id)sender
{
    [self.jotViewController clearAll];
}


@end
