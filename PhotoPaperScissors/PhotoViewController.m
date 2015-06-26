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
#import <NYXImagesKit/UIImage+Resizing.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import <ClusterPrePermissions/ClusterPrePermissions.h>
#import <NYXImagesKit/NYXImagesKit.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <MessageUI/MessageUI.h>
#import <FBSDKShareKit/FBSDKShareKit.h>

#import "PhotoViewController.h"
#import "PFAnalytics+PFAnalytics_TrackError.h"
#import "CEMovieMaker.h"

#define TimePerFrameInSeconds 2.0

@interface PhotoViewController () <MFMessageComposeViewControllerDelegate, FBSDKSharingDelegate>

@property (strong) CEMovieMaker *movieMaker;

@end

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
    photoImageViews = [NSMutableArray array];
    photoRoundIndicatorViews = [NSMutableArray array];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[RACObserve(self, theChallenge) filter:^BOOL(id value) {
        return (value != nil);
    }] subscribeNext:^(Challenge *aChallenge) {
        [self loadChallenge:aChallenge];
    }];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@" "
                                                                             style:self.navigationItem.backBarButtonItem.style
                                                                            target:nil
                                                                            action:nil];
    self.embededPhotos = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.embededPhotos.backgroundColor = [UIColor blackColor];
    self.embededPhotos.pagingEnabled = YES;
    self.embededPhotos.bounces = NO;
    [self.view addSubview:self.embededPhotos];
}

- (void)loadChallenge:(Challenge*)aChallenge
{
    if (self.embededPhotos == nil) {
        return;
    }
    
    ClusterPrePermissions *permission = [ClusterPrePermissions sharedPermissions];
    [permission showPushNotificationPermissionsWithType:UIUserNotificationTypeAlert | UIUserNotificationTypeSound | UIUserNotificationTypeBadge
                                                  title:@"Keep you in the loop?"
                                                message:@"Want us to let you know when someone challenges you or a new round starts?"
                                        denyButtonTitle:@"Not now"
                                       grantButtonTitle:@"Yes!"
                                      completionHandler:^(BOOL hasPermission, ClusterDialogResult userDialogResult, ClusterDialogResult systemDialogResult) {
                                          if (hasPermission) {
                                              [FBSDKAppEvents logEvent:@"permission"
                                                            parameters:@{FBSDKAppEventParameterNameContentType: @"notifications",
                                                                         FBSDKAppEventParameterNameSuccess: [NSNumber numberWithBool:YES]}];
                                              return;
                                          }
                                          if (userDialogResult == ClusterDialogResultDenied) {
                                              [FBSDKAppEvents logEvent:@"permission"
                                                            parameters:@{FBSDKAppEventParameterNameContentType: @"notifications",
                                                                         FBSDKAppEventParameterNameSuccess: [NSNumber numberWithBool:NO],
                                                                         @"source": @"userDialog"}];
                                          }
                                          if (systemDialogResult == ClusterDialogResultDenied) {
                                              [FBSDKAppEvents logEvent:@"permission"
                                                            parameters:@{FBSDKAppEventParameterNameContentType: @"notifications",
                                                                         FBSDKAppEventParameterNameSuccess: [NSNumber numberWithBool:NO],
                                                                         @"source": @"systemDialog"}];
                                          }
                                      }];
    
    self.title = aChallenge.challengeName;
    
    //delete stack between this and challenge screen
    NSMutableArray *controllers = [self.navigationController.viewControllers mutableCopy];
    NSRange range = {1, controllers.count-2};
    [controllers removeObjectsInRange:range];
    [self.navigationController setViewControllers:controllers];
    
    for (UIView *aView in photoImageViews) {
        [aView removeFromSuperview];
    }
    [photoImageViews removeAllObjects];
    
    for (UIView *aView in photoRoundIndicatorViews) {
        [aView removeFromSuperview];
    }
    [photoRoundIndicatorViews removeAllObjects];
    
    self.embededPhotos.contentSize = CGSizeZero;
    
    CGSize imageSize = CGSizeMake(self.embededPhotos.bounds.size.width, ceilf(self.embededPhotos.bounds.size.height/2.0));
    NSLog(@"size: %@, frame: %@", NSStringFromCGSize(imageSize), NSStringFromCGRect(self.embededPhotos.frame));
    
    for (int i=0; i<aChallenge.currentRoundNumber; i++) {
        if (i == (aChallenge.currentRoundNumber - 1) && aChallenge.whosTurn == myTurn) {
            break;
        }
        int roundNumber = i+1;
        UIImage *myImage = [aChallenge imageForPlayer:aChallenge.playerIAm forRound:roundNumber];
        UIImage *theirImage = [aChallenge imageForPlayer:aChallenge.otherPlayerIs forRound:roundNumber];
        
        if (myImage) {
            if (CGSizeEqualToSize(myImage.size, imageSize) == NO) {
                NSLog(@"two sized different: myImage=%@ and %@", NSStringFromCGSize(myImage.size), NSStringFromCGSize(imageSize));
            }
            UIImageView *myImageView = [[UIImageView alloc] initWithFrame:CGRectMake(i*imageSize.width, 0, imageSize.width, imageSize.height)];
            myImageView.backgroundColor = [UIColor blackColor];
            myImageView.contentMode = UIViewContentModeScaleAspectFill;
            myImageView.image = myImage;
            myImageView.clipsToBounds = YES;
            
            [self.embededPhotos addSubview:myImageView];
            [photoImageViews addObject:myImageView];
            
            self.embededPhotos.contentSize = CGSizeMake(CGRectGetMaxX(myImageView.frame), self.embededPhotos.bounds.size.height);
            //self.embededPhotos.contentOffset = CGPointMake(CGRectGetMinX(myImageView.frame), 0);
        }
        
        if (theirImage) {
            if (CGSizeEqualToSize(theirImage.size, imageSize) == NO) {
                NSLog(@"two sized different: theirIamge=%@ and %@", NSStringFromCGSize(theirImage.size), NSStringFromCGSize(imageSize));
            }
            UIImageView *theirImageView = [[UIImageView alloc] initWithFrame:CGRectMake(i*imageSize.width, imageSize.height-1, imageSize.width, imageSize.height)];
            theirImageView.backgroundColor = [UIColor blackColor];
            theirImageView.contentMode = UIViewContentModeScaleAspectFill;
            theirImageView.image = theirImage;
            theirImageView.clipsToBounds = YES;
            
            [self.embededPhotos addSubview:theirImageView];
            [photoImageViews addObject:theirImageView];
            
            self.embededPhotos.contentSize = CGSizeMake(CGRectGetMaxX(theirImageView.frame), self.embededPhotos.bounds.size.height);
            //self.embededPhotos.contentOffset = CGPointMake(CGRectGetMinX(theirImageView.frame), 0);
        }
        
        if (myImage || theirImage) {
            if (roundNumber == aChallenge.maxRounds
                && (myImage && theirImage)) {
                UIButton *shareToTwitter = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
                [shareToTwitter setImage:[UIImage imageNamed:@"twitter"] forState:UIControlStateNormal];
                [shareToTwitter addTarget:self action:@selector(sendToShareSheet) forControlEvents:UIControlEventTouchUpInside];
                shareToTwitter.backgroundColor = [UIColor blackColor];
                shareToTwitter.clipsToBounds = YES;
                shareToTwitter.layer.cornerRadius = shareToTwitter.bounds.size.width/2.0;
                shareToTwitter.center = CGPointMake(self.embededPhotos.bounds.size.width * (i+0.8), self.embededPhotos.bounds.size.height/2.0);
                [self.embededPhotos addSubview:shareToTwitter];
                [photoRoundIndicatorViews addObject:shareToTwitter];
                
                UIButton *shareToSMS = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
                [shareToSMS setImage:[UIImage imageNamed:@"messages"] forState:UIControlStateNormal];
                [shareToSMS addTarget:self action:@selector(sendGifToSMS) forControlEvents:UIControlEventTouchUpInside];
                shareToSMS.backgroundColor = [UIColor blackColor];
                shareToSMS.clipsToBounds = YES;
                shareToSMS.layer.cornerRadius = shareToSMS.bounds.size.width/2.0;
                shareToSMS.center = CGPointMake(self.embededPhotos.bounds.size.width * (i+0.6), self.embededPhotos.bounds.size.height/2.0);
                [self.embededPhotos addSubview:shareToSMS];
                [photoRoundIndicatorViews addObject:shareToSMS];
                
                UIButton *shareToFB = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
                [shareToFB setImage:[UIImage imageNamed:@"facebook"] forState:UIControlStateNormal];
                [shareToFB addTarget:self action:@selector(sendToFacebook:) forControlEvents:UIControlEventTouchUpInside];
                shareToFB.backgroundColor = [UIColor blackColor];
                shareToFB.clipsToBounds = YES;
                shareToFB.layer.cornerRadius = shareToFB.bounds.size.width/2.0;
                shareToFB.center = CGPointMake(self.embededPhotos.bounds.size.width * (i+0.4), self.embededPhotos.bounds.size.height/2.0);
                [self.embededPhotos addSubview:shareToFB];
                [photoRoundIndicatorViews addObject:shareToFB];
                
                UIButton *shareToCameraRoll = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
                [shareToCameraRoll setImage:[UIImage imageNamed:@"camera_roll"] forState:UIControlStateNormal];
                [shareToCameraRoll addTarget:self action:@selector(makeAnimatedGif:) forControlEvents:UIControlEventTouchUpInside];
                shareToCameraRoll.backgroundColor = [UIColor blackColor];
                shareToCameraRoll.clipsToBounds = YES;
                shareToCameraRoll.layer.cornerRadius = shareToCameraRoll.bounds.size.width/2.0;
                shareToCameraRoll.center = CGPointMake(self.embededPhotos.bounds.size.width * (i+0.2), self.embededPhotos.bounds.size.height/2.0);
                [self.embededPhotos addSubview:shareToCameraRoll];
                [photoRoundIndicatorViews addObject:shareToCameraRoll];
            } else {
                UIView *roundIndicator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
                roundIndicator.backgroundColor = [UIColor blackColor];
                roundIndicator.clipsToBounds = YES;
                roundIndicator.layer.cornerRadius = roundIndicator.bounds.size.width/2.0;
                roundIndicator.center = CGPointMake(self.embededPhotos.bounds.size.width * (i+0.5), self.embededPhotos.bounds.size.height/2.0);
                [self.embededPhotos addSubview:roundIndicator];
                [photoRoundIndicatorViews addObject:roundIndicator];
                
                UILabel *roundNumberLabel = [[UILabel alloc] initWithFrame:roundIndicator.bounds];
                roundNumberLabel.text = [NSString stringWithFormat:@"%d", roundNumber];
                roundNumberLabel.textColor = [UIColor whiteColor];
                roundNumberLabel.textAlignment = NSTextAlignmentCenter;
                [roundIndicator addSubview:roundNumberLabel];
            }
        }
    }
    
    if (aChallenge.whosTurn == myTurn) {
        //show previous round
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Play Round"
                                                                                  style:self.editButtonItem.style
                                                                                 target:self
                                                                                 action:@selector(showCamera:)];
        return;
    }
    
    if (aChallenge.challengeComplete) {
        //all rounds complete
        /*
         self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save to library"
                                                                                  style:self.editButtonItem.style
                                                                                 target:self
                                                                                 action:@selector(makeAnimatedGif:)];
         */
        return;
    }
    
    if (aChallenge.whosTurn == noonesTurn && aChallenge.currentRoundNumber < aChallenge.maxRounds) {
            //Current round is complete
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next Round"
                                                                                      style:self.editButtonItem.style
                                                                                     target:self
                                                                                     action:@selector(nextRound:)];
        return;
    }

     self.navigationItem.rightBarButtonItem = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self positionEmbeddedView];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.tabBarController.tabBar.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    self.embededPhotos.contentOffset = CGPointMake(0, 0);
    [UIView animateWithDuration:1.0 animations:^{
        self.embededPhotos.contentOffset = CGPointMake(self.embededPhotos.contentSize.width-self.embededPhotos.bounds.size.width, 0);
    }];
}

- (void)positionEmbeddedView
{
    CGRect embedFrame = CGRectOffset(self.view.bounds, 0, -1 * self.view.frame.origin.y);
    embedFrame.size.height += self.view.frame.origin.y;
    self.embededPhotos.frame = embedFrame;
    [self loadChallenge:self.theChallenge];
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showCamera"]) {
        PhotoViewController *controller = (PhotoViewController*)segue.destinationViewController;
        controller.theChallenge = self.theChallenge;
    }
}

- (IBAction)makeAnimatedGif:(id)sender
{
    if ([sender respondsToSelector:@selector(setEnabled:)]) {
        [sender setEnabled:NO];
    }
    
    [self createAndSaveAnimatedGifWithCompletetion:^(NSError *error) {
        if ([sender respondsToSelector:@selector(setEnabled:)]) {
            [sender setEnabled:YES];
        }
        if (!error) {
            UIAlertView *alerting = [[UIAlertView alloc] initWithTitle:@"Saved"
                                                               message:@"GIF & video saved to Camera Roll"
                                                              delegate:nil
                                                     cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil];
            [alerting show];
        }
    }];
}

- (IBAction)sendToFacebook:(id)sender
{
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fb:"]]) {
        UIButton *buttonFrom = (UIButton*)sender;
        buttonFrom.enabled = NO;
        NSArray *images = [self collectImages];
        [self createVideoFrom:images withCompletetion:^(NSError *error, NSURL *fileURL) {
            if (fileURL) {
                ALAssetsLibrary *al = [[ALAssetsLibrary alloc] init];
                [al writeVideoAtPathToSavedPhotosAlbum:fileURL completionBlock:^(NSURL *assetURL, NSError *error) {
                    buttonFrom.enabled = YES;
                    if (error) {
                        NSLog(@"Error %@", error);
                        [PFAnalytics trackErrorIn:NSStringFromSelector(_cmd) withComment:@"writeImageDataToSavedPhotosAlbum" withError:error];
                        return;
                    }
                    
                    FBSDKShareVideo *videoShare = [FBSDKShareVideo videoWithVideoURL:assetURL];
                    FBSDKSharePhoto *photoPreview = [FBSDKSharePhoto photoWithImage:images[0] userGenerated:YES];
                    FBSDKShareVideoContent  *toShare = [[FBSDKShareVideoContent alloc] init];
                    toShare.video = videoShare;
                    toShare.previewPhoto = photoPreview;
                    toShare.peopleIDs = @[];
                    toShare.placeID = @"";
                    [FBSDKShareDialog showFromViewController:self withContent:toShare delegate:self];
                }];
            } else {
                buttonFrom.enabled = YES;
            }
        }];
    } else {
        UIAlertView *alerting = [[UIAlertView alloc] initWithTitle:@"Sorry"
                                                           message:@"You must have the facebook client installed to upload video"
                                                          delegate:nil
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
        [alerting show];
    }
}

- (void)createAndSaveAnimatedGifWithCompletetion:(void (^)(NSError*))completionBlock
{
    NSArray *images = [self collectImages];
    __block NSError *groupError = nil;
    
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_enter(group);
    [self createVideoFrom:images withCompletetion:^(NSError *error, NSURL *fileURL) {
        if (fileURL) {
            ALAssetsLibrary *al = [[ALAssetsLibrary alloc] init];
            [al writeVideoAtPathToSavedPhotosAlbum:fileURL completionBlock:^(NSURL *assetURL, NSError *error) {
                dispatch_group_leave(group);
                if (error) {
                    NSLog(@"Error %@", error);
                    [PFAnalytics trackErrorIn:NSStringFromSelector(_cmd) withComment:@"writeImageDataToSavedPhotosAlbum" withError:error];
                    groupError = error;
                    return;
                }
            }];
        } else {
            dispatch_group_leave(group);
        }
    }];
    
    NSData *gifData = [self createAnimatedGiFrom:images];
    
    ALAssetsLibrary *al = [[ALAssetsLibrary alloc] init];
    dispatch_group_enter(group);
    [al writeImageDataToSavedPhotosAlbum:gifData metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
        dispatch_group_leave(group);
        if (error) {
            NSLog(@"Error %@", error);
            [PFAnalytics trackErrorIn:NSStringFromSelector(_cmd) withComment:@"writeImageDataToSavedPhotosAlbum" withError:error];
            groupError = error;
            return;
        }
    }];
    
    dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if (completionBlock) {
            completionBlock(groupError);
        }
    });
}

- (void)sendToShareSheet
{
    NSArray *images = [self collectImages];
    NSData *gifData = [self createAnimatedGiFrom:images];
    
    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[gifData, self.theChallenge.challengeName]
                                                                             applicationActivities:nil];
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)sendGifToSMS
{
    NSArray *images = [self collectImages];
    NSData *gifData = [self createAnimatedGiFrom:images];
    
    if(![MFMessageComposeViewController canSendText]) {
        UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your device doesn't support SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [warningAlert show];
        return;
    }
    
    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
    [messageController setBody:self.theChallenge.challengeName];
    [messageController addAttachmentData:gifData typeIdentifier:@"com.compuserve.gif" filename:@"rpp.gif"];
    
    messageController.messageComposeDelegate = self;
    [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:messageController animated:YES completion:nil];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [[[[UIApplication sharedApplication] keyWindow] rootViewController] dismissViewControllerAnimated:YES completion:nil];
}

- (NSData*)createAnimatedGiFrom:(NSArray*)images
{
    
    
    NSDictionary *fileProperties = @{
                                     (__bridge id)kCGImagePropertyGIFDictionary: @{
                                             (__bridge id)kCGImagePropertyGIFLoopCount: @0, // 0 means loop forever
                                             }
                                     };
    
    NSDictionary *frameProperties = @{
                                      (__bridge id)kCGImagePropertyGIFDictionary: @{
                                              (__bridge id)kCGImagePropertyGIFDelayTime: @(TimePerFrameInSeconds), // a float (not double!) in seconds, rounded to centiseconds in the GIF data
                                              }
                                      };
    
    
    CFMutableDataRef gifData = CFDataCreateMutable(kCFAllocatorDefault, 0);
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithData(gifData, kUTTypeGIF, images.count, NULL);
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)fileProperties);
    
    for (int i=0; i<images.count; i++) {
        UIImage *image = images[i];
        CGImageDestinationAddImage(destination, image.CGImage, (__bridge CFDictionaryRef)frameProperties);
    }
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"failed to finalize image destination");
    }
    CFRelease(destination);
    
    return CFBridgingRelease(gifData);
}

- (NSArray*)collectImages
{
    NSMutableArray *images = [NSMutableArray array];
    
    NSArray *size = [[PFConfig currentConfig] objectForKey:@"SizeOfExportGif"];
    if (size == nil || size.count != 2) {
        size = @[@(470), @(836)];
    }
    CGFloat width = [size[0] floatValue];
    CGFloat height = [size[1] floatValue];
    if (fmodf(width,16.0) != 0) {
        CGFloat newWidth = ceilf(width / 16) * 16;
        CGFloat newHeight = ceilf(newWidth * height / width);
        size = @[@(newWidth), @(newHeight)];
    }
    CGSize blockSize = CGSizeMake([size[0] integerValue], ceilf([size[1] floatValue] / 2.0));
    CGSize finalSize = CGSizeMake(blockSize.width, blockSize.height*2);
    
    UIImage *challengeCover = [self.theChallenge.theme coverphoto];
    if (challengeCover == nil) {
        challengeCover = [self drawText:self.theChallenge.challengeName intoSize:finalSize];
    } else {
        challengeCover = [[challengeCover scaleToCoverSize:finalSize] cropToSize:finalSize usingMode:NYXCropModeCenter];
    }
    [images addObject:challengeCover];
    
    for (NSUInteger i = 0; i < self.theChallenge.maxRounds; i++) {
        UIImage *image = [self drawTop:[self.theChallenge imageForPlayer:Challenger forRound:(i+1)]
                            drawBottom:[self.theChallenge imageForPlayer:Challengee forRound:(i+1)]
                         intoImageSize:blockSize];
        [images addObject:image];
    }
    
    return images;
}

- (UIImage *)drawText:(NSString*)string intoSize:(CGSize)finalSize
{
    UIGraphicsBeginImageContextWithOptions(finalSize, YES, 1.0);
    
    // get context
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // push context to make it current
    // (need to do this manually because we are not drawing in a UIView)
    UIGraphicsPushContext(context);
    
    // drawing code comes here- look at CGContext reference
    // for available operations
    // this example draws the inputImage into the context
    // Create text
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);

    NSDictionary *attributes = @{ NSForegroundColorAttributeName : [UIColor whiteColor],
                                  NSBackgroundColorAttributeName : [UIColor clearColor],
                                  NSFontAttributeName : [UIFont systemFontOfSize:60.0]};
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:string attributes:attributes];
    CGSize stringSize = [attrString size];
    
    // Rotate the context (convert to radians)
    CGAffineTransform transform1 = CGAffineTransformMakeRotation(45 * M_PI/180);
    CGContextConcatCTM(context, transform1);
    
    // Draw the string

    [attrString drawInRect:CGRectMake(50, 0, stringSize.width, stringSize.height)];
    
    // pop context
    UIGraphicsPopContext();
    
    // get a UIImage from the image context- enjoy!!!
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // clean up drawing environment
    UIGraphicsEndImageContext();
    
    return outputImage;
}

- (UIImage *)drawTop:(UIImage *)topImage drawBottom:(UIImage*)bottomImage intoImageSize:(CGSize)blockSize
{
    CGSize finalSize = CGSizeMake(blockSize.width, blockSize.height*2);
    
    // create a new bitmap image context at the device resolution (retina/non-retina)
    UIGraphicsBeginImageContextWithOptions(finalSize, YES, 1.0);
    
    // get context
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // push context to make it current
    // (need to do this manually because we are not drawing in a UIView)
    UIGraphicsPushContext(context);
    
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    
    // drawing code comes here- look at CGContext reference
    // for available operations
    // this example draws the inputImage into the context
    [[[topImage scaleToCoverSize:blockSize] cropToSize:blockSize usingMode:NYXCropModeCenter]  drawInRect:CGRectMake(0, 0, blockSize.width, blockSize.height)];
    [[[bottomImage scaleToCoverSize:blockSize] cropToSize:blockSize usingMode:NYXCropModeCenter] drawInRect:CGRectMake(0, blockSize.height, blockSize.width, blockSize.height)];
    
    // pop context
    UIGraphicsPopContext();
    
    // get a UIImage from the image context- enjoy!!!
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // clean up drawing environment
    UIGraphicsEndImageContext();
    
    return outputImage;
}

- (void)createVideoFrom:(NSArray*)imageArray withCompletetion:(void (^)(NSError *error, NSURL* fileURL))completionBlock
{
    UIImage *anImage = [imageArray firstObject];
    CGSize size = anImage.size;
    
    NSDictionary *settings = [CEMovieMaker videoSettingsWithCodec:AVVideoCodecH264
                                                        withWidth:size.width
                                                        andHeight:size.height];
    self.movieMaker = [[CEMovieMaker alloc] initWithSettings:settings];
    self.movieMaker.frameTime = CMTimeMake(TimePerFrameInSeconds, 1); //seconds, frames in those seconds
    [self.movieMaker createMovieFromImages:imageArray withCompletion:^(NSURL *fileURL){
        if (fileURL) {
            if (completionBlock) {
                completionBlock(nil, fileURL);
            }
        } else {
            if (completionBlock) {
                completionBlock([NSError errorWithDomain:@"eek" code:1 userInfo:nil], nil);
            }
        }
    }];
}

#pragma mark Facebook Delegate

- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results
{
    
}

- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error
{
    
}

- (void)sharerDidCancel:(id<FBSDKSharing>)sharer
{
    
}

@end
