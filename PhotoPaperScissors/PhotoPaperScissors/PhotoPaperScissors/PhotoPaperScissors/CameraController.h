//
//  CameraController.h
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/15/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Challenge.h"

@interface CameraController : UIViewController

@property IBOutlet UIView *cameraContainer;
@property IBOutlet UIButton *flashButton;
@property IBOutlet UIButton *shutterButton;
@property IBOutlet UIButton *cameraButton;
@property UIImage *takenPhoto;

@property IBOutlet UIView *blackColorSwatch;
@property IBOutlet UIView *whiteColorSwatch;
@property IBOutlet UIButton *clearButton;

@property IBOutlet UIView *drawContainer;
@property IBOutlet UIView *cameraControlContainer;

@property IBOutlet UIButton *drawSelectButton;
@property IBOutlet UIButton *textSelectButton;
@property IBOutlet UIButton *clearDrawButton;

@property IBOutletCollection(UIView) NSArray *colorSelectors;

@property Challenge *theChallenge;

@end
