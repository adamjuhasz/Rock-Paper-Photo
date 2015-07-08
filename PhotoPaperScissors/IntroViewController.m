//
//  IntroViewController.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 7/1/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "IntroViewController.h"

#import <Colours/Colours.h>

@interface IntroViewController ()
{
    UIImage *introImage;
    UIImageView *introImageView;
    UIButton *getStarted;
    BOOL alreadyPresenting;
}

@end

@implementation IntroViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    alreadyPresenting = NO;
    
    introImage = [UIImage imageNamed:@"intro"];
    if (introImage == nil) {
        introImage = [UIImage imageNamed:@"intro.jpg"];
    }
    
    CGFloat zoomScale = self.mainScroller.bounds.size.width / introImage.size.width;
    introImageView = [[UIImageView alloc] initWithImage:introImage];
    introImageView.frame = CGRectMake(0, 0, self.mainScroller.bounds.size.width, introImage.size.height * zoomScale);
    introImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.mainScroller addSubview:introImageView];
    [self.mainScroller setContentSize:introImageView.bounds.size];
    
    getStarted = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    getStarted.layer.cornerRadius = 3.0;
    [getStarted setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [getStarted setTitle:@"Get Started" forState:UIControlStateNormal];
    getStarted.backgroundColor = [UIColor colorFromHexString:@"#6F70FF"];
    [getStarted addTarget:self action:@selector(getItStarted) forControlEvents:UIControlEventTouchUpInside];
    getStarted.bounds = CGRectMake(0, 0, self.mainScroller.bounds.size.width - 80, 44);
    getStarted.center = CGPointMake(CGRectGetMidX(self.mainScroller.bounds), CGRectGetMaxY(self.mainScroller.bounds) + 10 + CGRectGetMidY(getStarted.bounds));
    [self.mainScroller addSubview:getStarted];
    [self.mainScroller setContentSize:CGSizeMake(self.mainScroller.bounds.size.width, CGRectGetMaxY(getStarted.frame) + 10)];
}

- (void)viewDidLayoutSubviews
{
    CGFloat zoomScale = self.mainScroller.bounds.size.width / introImage.size.width;
    introImageView.frame = CGRectMake(0, 0, self.mainScroller.bounds.size.width, introImage.size.height * zoomScale);
    [self.mainScroller setContentSize:introImageView.bounds.size];
    
    getStarted.bounds = CGRectMake(0, 0, self.mainScroller.bounds.size.width - 80, 44);
    getStarted.center = CGPointMake(CGRectGetMidX(self.mainScroller.bounds), self.mainScroller.contentSize.height + 10 + CGRectGetMidY(getStarted.bounds));
    [self.mainScroller setContentSize:CGSizeMake(self.mainScroller.bounds.size.width, CGRectGetMaxY(getStarted.frame) + 10)];
}

- (IBAction)getItStarted
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
