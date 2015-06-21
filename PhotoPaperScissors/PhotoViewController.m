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

#import "PhotoViewController.h"
#import "PFAnalytics+PFAnalytics_TrackError.h"


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

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    RAC(self.otherUserPhoto, image) = [RACObserve(self, otherUserImage) filter:^BOOL(id value) {
        return (value != nil);
    }];
    RAC(self.myPhoto, image) = RACObserve(self, myImage);
    
    [[RACObserve(self, theChallenge) filter:^BOOL(id value) {
        return (value != nil);
    }] subscribeNext:^(Challenge *aChallenge) {
        [self loadChallenge:aChallenge];
    }];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@" "
                                                                             style:self.navigationItem.backBarButtonItem.style
                                                                            target:nil
                                                                            action:nil];
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
    
    self.myImage = [aChallenge imageForPlayer:aChallenge.playerIAm forRound:aChallenge.currentRoundNumber];
    
    if (aChallenge.currentRoundNumber > 1 && self.myImage == nil) {
        //show previous round
        NSUInteger roundNumberToShow = (aChallenge.currentRoundNumber-1);
        self.myImage = [aChallenge imageForPlayer:aChallenge.playerIAm forRound:roundNumberToShow];
        [self showImageForOtherPlayerIfIAm:aChallenge.playerIAm fromChallenge:aChallenge withRound:roundNumberToShow];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Start next Round"
                                                                                  style:self.editButtonItem.style
                                                                                 target:self
                                                                                 action:@selector(showCamera:)];
        return;
    }
    
    //will load self.otherUserImage
    [self showImageForOtherPlayerIfIAm:aChallenge.playerIAm fromChallenge:aChallenge withRound:aChallenge.currentRoundNumber];
    
    if (aChallenge.challengeComplete) {
        //all rounds complete
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save to library"
                                                                                  style:self.editButtonItem.style
                                                                                 target:self
                                                                                 action:@selector(makeAnimatedGif)];
        return;
    }
    
    if (self.otherUserImage && aChallenge.currentRoundNumber < aChallenge.maxRounds) {
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showCamera"]) {
        PhotoViewController *controller = (PhotoViewController*)segue.destinationViewController;
        controller.theChallenge = self.theChallenge;
    }
}

- (void) makeAnimatedGif
{
    NSArray *size = [[PFConfig currentConfig] objectForKey:@"SizeOfExportGif"];
    if (size == nil || size.count != 2) {
        size = @[@(470), @(836)];
    }
    CGSize blockSize = CGSizeMake([size[0] integerValue], ceilf([size[1] floatValue] / 2.0));
    CGSize finalSize = CGSizeMake(blockSize.width, blockSize.height*2);
    
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
    
    NSMutableArray *images = [NSMutableArray array];
    CFMutableDataRef gifData = CFDataCreateMutable(kCFAllocatorDefault, 0);
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithData(gifData, kUTTypeGIF, kFrameCount+1, NULL);
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)fileProperties);
    
    
    UIImage *challengeCover = [self.theChallenge.theme coverphoto];
    if (challengeCover == nil) {
        challengeCover = [self drawText:self.theChallenge.challengeName intoSize:finalSize];
    } else {
        challengeCover = [[challengeCover scaleToCoverSize:finalSize] cropToSize:finalSize usingMode:NYXCropModeCenter];
    }
    CGImageDestinationAddImage(destination, challengeCover.CGImage, (__bridge CFDictionaryRef)frameProperties);
    [images addObject:challengeCover];
    
    for (NSUInteger i = 0; i < kFrameCount; i++) {
        UIImage *image = [self drawTop:[self.theChallenge imageForPlayer:Challenger forRound:(i+1)]
                            drawBottom:[self.theChallenge imageForPlayer:Challengee forRound:(i+1)]
                         intoImageSize:blockSize];
        [images addObject:image];
        CGImageDestinationAddImage(destination, image.CGImage, (__bridge CFDictionaryRef)frameProperties);
    }
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"failed to finalize image destination");
    }
    CFRelease(destination);
    
    ALAssetsLibrary *al = [[ALAssetsLibrary alloc] init];
    [al writeImageDataToSavedPhotosAlbum:(NSData*)CFBridgingRelease(gifData) metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error) {
            NSLog(@"Error %@", error);
        }
    }];
    
    [self createVideoFrom:images];
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
    
    // drawing code comes here- look at CGContext reference
    // for available operations
    // this example draws the inputImage into the context
    [[topImage scaleToCoverSize:blockSize] drawInRect:CGRectMake(0, 0, blockSize.width, blockSize.height)];
    [[bottomImage scaleToCoverSize:blockSize] drawInRect:CGRectMake(0, blockSize.height, blockSize.width, blockSize.height)];
    
    // pop context
    UIGraphicsPopContext();
    
    // get a UIImage from the image context- enjoy!!!
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // clean up drawing environment
    UIGraphicsEndImageContext();
    
    return outputImage;
}

- (void)createVideoFrom:(NSArray*)imageArray
{
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/movie.mp4"]];
    NSString *documentsDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectoryPath error:nil];
    for (NSString *tString in dirContents) {
        if ([tString isEqualToString:@"movie.mp4"])
        {
            //Remove File existed.
            [[NSFileManager defaultManager]removeItemAtPath:[NSString stringWithFormat:@"%@/%@",documentsDirectoryPath,tString] error:nil];
        }
    }

    UIImage *anImage = imageArray[0];
    //[self writeImageAsMovie:imageArray toPath:path size:anImage.size duration:1];
}
/*
- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef)image  size:(CGSize)imageSize
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, imageSize.width,
                                          imageSize.height, kCVPixelFormatType_32ARGB, (CFDictionaryRef) CFBridgingRetain(options),
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, imageSize.width,
                                                 imageSize.height, 8, 4*imageSize.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    //    CGContextConcatCTM(context, frameTransform);
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

-(void)writeImageAsMovie:(NSArray *)array toPath:(NSString*)path size:(CGSize)size duration:(int)duration
{
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path]
                                                           fileType:AVFileTypeMPEG4
                                                              error:&error];
    NSParameterAssert(videoWriter);
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                   nil];
    AVAssetWriterInput* writerInput = [[AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                          outputSettings:videoSettings] retain];
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                                                                                     sourcePixelBufferAttributes:nil];
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    [videoWriter addInput:writerInput];
    //Start a session:
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    CVPixelBufferRef buffer = NULL;
    buffer = [self pixelBufferFromCGImage:[[array objectAtIndex:0] CGImage] size:CGSizeMake(640, 1136)];
    CVPixelBufferPoolCreatePixelBuffer (NULL, adaptor.pixelBufferPool, &buffer);
    [adaptor appendPixelBuffer:buffer withPresentationTime:kCMTimeZero];
    
    int i = 1;
    while (1)
    {
        if(writerInput.readyForMoreMediaData){
            CMTime frameTime = CMTimeMake(1, 10);
            CMTime lastTime=CMTimeMake(i, 10);
            CMTime presentTime=CMTimeAdd(lastTime, frameTime);
            if (i >= [array count])
            {
                buffer = NULL;
            }
            else
            {
                buffer = [self pixelBufferFromCGImage:[[array objectAtIndex:i] CGImage] size:CGSizeMake(640, 1136)];
            }
            if (buffer)
            {
                // append buffer
                [adaptor appendPixelBuffer:buffer withPresentationTime:presentTime];
                i++;
            }
            else
            {
                //Finish the session:
                [writerInput markAsFinished];
                //If change to fininshWritingWith... Cause Zero bytes file. I'm Trying to fix.
                [videoWriter finishWriting];
                CVPixelBufferPoolRelease(adaptor.pixelBufferPool);
                [videoWriter release];
                [writerInput release];
                NSLog (@"Done");
                break;
            }
        }
    }
}
*/
@end
