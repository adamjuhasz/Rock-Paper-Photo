//
//  PhotoViewController.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/15/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "ANGifEncoder.h"

#import "PhotoViewController.h"

@implementation PhotoViewController

- (id)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.nextAction = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.nextAction.layer.cornerRadius = 6.0;
    self.nextAction.backgroundColor = [UIColor blackColor];
    [self.nextAction setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.nextAction.bounds = CGRectMake(0, 0, 200, 66);
    self.nextAction.center = CGPointMake(self.view.bounds.size.width/2.0, self.view.bounds.size.height/2.0);
    [self.view addSubview:self.nextAction];
    
    RAC(self.otherUserPhoto, image) = [RACObserve(self, otherUserImage) filter:^BOOL(id value) {
        return (value != nil);
    }];
    RAC(self.myPhoto, image) = RACObserve(self, myImage);
    
    [[RACObserve(self, theChallenge) filter:^BOOL(id value) {
        return (value != nil);
    }] subscribeNext:^(Challenge *aChallenge) {
        [self loadChallenge:aChallenge];
    }];
}

- (void)showImageForOtherPlayerIfIAm:(PlayerType)playerType fromChallenge:(Challenge*)aChallenge withRound:(NSUInteger)roundNumberToShow
{
    switch (playerType) {
        case Challengee:
            self.otherUserImage = [aChallenge imageForPlayer:Challenger forRound:roundNumberToShow];
            break;
            
        case Challenger:
            self.otherUserImage = [aChallenge imageForPlayer:Challengee forRound:roundNumberToShow];
            break;
            
        case Unknown:
            self.myImage = [aChallenge imageForPlayer:Challenger forRound:roundNumberToShow];
            self.otherUserImage = [aChallenge imageForPlayer:Challengee forRound:roundNumberToShow];
            break;
    }
}

- (void)loadChallenge:(Challenge*)aChallenge
{
    [self.nextAction removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
    
    self.myImage = [aChallenge imageForPlayer:aChallenge.playerIAm forRound:aChallenge.currentRoundNumber];
    if (aChallenge.currentRoundNumber > 1 && self.myImage == nil) {
        //show previous round
        NSUInteger roundNumberToShow = (aChallenge.currentRoundNumber-1);
        self.myImage = [aChallenge imageForPlayer:aChallenge.playerIAm forRound:roundNumberToShow];
        [self showImageForOtherPlayerIfIAm:aChallenge.playerIAm fromChallenge:aChallenge withRound:roundNumberToShow];
        [self.nextAction setTitle:@"Next Round" forState:UIControlStateNormal];
        [self.nextAction addTarget:self action:@selector(showCamera:) forControlEvents:UIControlEventTouchUpInside];
        return;
    }
    
    if (aChallenge.photoSent == NO) {
        //dont't show other photo, we can only send it
        [self.nextAction setTitle:@"Send" forState:UIControlStateNormal];
        [self.nextAction addTarget:self action:@selector(send:) forControlEvents:UIControlEventTouchUpInside];
        return;
    }
    
    [self showImageForOtherPlayerIfIAm:aChallenge.playerIAm fromChallenge:aChallenge withRound:aChallenge.currentRoundNumber];
    
    if (aChallenge.playerIAm == Unknown) {
        [self.nextAction setTitle:@"" forState:UIControlStateNormal];
        return;
    }
    
    if (self.otherUserImage) {
        if (aChallenge.challengeComplete) {
            //all rounds complete
            [self.nextAction setTitle:@"Save & Share" forState:UIControlStateNormal];
            [self.nextAction addTarget:self action:@selector(makeAnimatedGif) forControlEvents:UIControlEventTouchUpInside];
        } else {
            //Round is complete
            [self.nextAction setTitle:@"Next Round" forState:UIControlStateNormal];
            [self.nextAction addTarget:self action:@selector(nextRound:) forControlEvents:UIControlEventTouchUpInside];
        }
    } else {
        //no image from other user for this round, show photo
        [self.nextAction setTitle:@"Waiting..." forState:UIControlStateNormal];
    }
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

- (IBAction)nextRound:(id)sender
{
    self.theChallenge.currentRoundNumber += 1;
    [self.theChallenge save];
    
    [self showCamera:sender];
}

- (IBAction)showCamera:(id)sender
{
    [self performSegueWithIdentifier:@"showCamera" sender:self];
}

- (IBAction)send:(id)sender
{
    [self.theChallenge save];
    //if we are completing a challenge round, show both photos
    if ([self.theChallenge imageForPlayer:self.theChallenge.playerIAm forRound:self.theChallenge.currentRoundNumber] != nil &&
        [self.theChallenge imageForPlayer:self.theChallenge.otherPlayerIs forRound:self.theChallenge.currentRoundNumber] != nil) {
        [self loadChallenge:self.theChallenge];
    } else {
        //we have to wait for other player to respond to this new photo
        self.tabBarController.tabBar.hidden = NO;
        self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showCamera"]) {
        PhotoViewController *controller = (PhotoViewController*)segue.destinationViewController;
        controller.theChallenge = self.theChallenge;
    }
}


- (void) makeAnimatedGif
{
    ANGifEncoder *giffer = [ANGifEncoder alloc] initWithOutputFile:@"mygif.gif" size:CGSizeMake(<#CGFloat width#>, <#CGFloat height#>) globalColorTable:<#(ANColorTable *)#>
    
    NSUInteger kFrameCount = self.theChallenge.maxRounds;
    
    NSDictionary *fileProperties = @{
                                     (__bridge id)kCGImagePropertyGIFDictionary: @{
                                             (__bridge id)kCGImagePropertyGIFLoopCount: @0, // 0 means loop forever
                                             }
                                     };
    
    NSDictionary *frameProperties = @{
                                      (__bridge id)kCGImagePropertyGIFDictionary: @{
                                              (__bridge id)kCGImagePropertyGIFDelayTime: @1.0f, // a float (not double!) in seconds, rounded to centiseconds in the GIF data
                                              }
                                      };
    
    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    NSURL *fileURL = [documentsDirectoryURL URLByAppendingPathComponent:@"animated.gif"];
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)fileURL, kUTTypeGIF, kFrameCount, NULL);
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)fileProperties);
    
    for (NSUInteger i = 0; i < kFrameCount; i++) {
        UIImage *image = [self drawTop:[self.theChallenge imageForPlayer:Challenger forRound:(i+1)]
                            drawBottom:[self.theChallenge imageForPlayer:Challengee forRound:(i+1)]] ;
        CGImageDestinationAddImage(destination, image.CGImage, (__bridge CFDictionaryRef)frameProperties);
    }
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"failed to finalize image destination");
    }
    CFRelease(destination);
}

- (UIImage *)drawTop:(UIImage *)topImage drawBottom:(UIImage*)bottomImage
{
    CGSize finalSize = CGSizeMake(MIN(topImage.size.width, bottomImage.size.width), topImage.size.height + bottomImage.size.height);
    
    // create a new bitmap image context at the device resolution (retina/non-retina)
    UIGraphicsBeginImageContextWithOptions(finalSize, YES, 0.0);
    
    // get context
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // push context to make it current
    // (need to do this manually because we are not drawing in a UIView)
    UIGraphicsPushContext(context);
    
    // drawing code comes here- look at CGContext reference
    // for available operations
    // this example draws the inputImage into the context
    [topImage drawInRect:CGRectMake(0, 0, finalSize.width, topImage.size.height)];
    [bottomImage drawInRect:CGRectMake(0, topImage.size.height, finalSize.width, bottomImage.size.height)];
    
    // pop context
    UIGraphicsPopContext();
    
    // get a UIImage from the image context- enjoy!!!
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // clean up drawing environment
    UIGraphicsEndImageContext();
    
    return outputImage;
}

@end
