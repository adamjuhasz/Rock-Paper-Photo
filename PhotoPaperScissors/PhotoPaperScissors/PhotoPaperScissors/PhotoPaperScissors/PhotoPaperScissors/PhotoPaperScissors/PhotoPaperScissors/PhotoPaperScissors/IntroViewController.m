//
//  IntroViewController.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 7/1/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "IntroViewController.h"

@interface IntroViewController ()

@end

@implementation IntroViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIImage *introImage = [UIImage imageNamed:@"intro"];
    if (introImage == nil) {
        introImage = [UIImage imageNamed:@"intro.jpg"];
    }
    UIImageView *introImageView = [[UIImageView alloc] initWithImage:introImage];
    [self.mainScroller addSubview:introImageView];
    [self.mainScroller setContentSize:introImage.size];
    [self.mainScroller setZoomScale:introImage.size.width / self.mainScroller.bounds.size.width];
}

@end
