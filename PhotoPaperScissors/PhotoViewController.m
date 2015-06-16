//
//  PhotoViewController.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/15/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "PhotoViewController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

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
        self.myImage = [aChallenge imageForPlayer:aChallenge.playerIAm forRound:aChallenge.currentRoundNumber];
        switch (aChallenge.playerIAm) {
            case Challengee:
                self.otherUserImage = [aChallenge imageForPlayer:Challenger forRound:aChallenge.currentRoundNumber];
                if (self.otherUserImage) {
                    [self.nextAction setTitle:@"Next Round" forState:UIControlStateNormal];
                    [self.nextAction addTarget:self action:@selector(nextRound:) forControlEvents:UIControlEventTouchUpInside];
                } else {
                    [self.nextAction setTitle:@"Send" forState:UIControlStateNormal];
                    [self.nextAction addTarget:self action:@selector(send:) forControlEvents:UIControlEventTouchUpInside];
                }
                break;
                
            case Challenger:
                self.otherUserImage = [aChallenge imageForPlayer:Challengee forRound:aChallenge.currentRoundNumber];
                if (self.otherUserImage) {
                    [self.nextAction setTitle:@"Next Round" forState:UIControlStateNormal];
                    [self.nextAction addTarget:self action:@selector(nextRound:) forControlEvents:UIControlEventTouchUpInside];
                } else {
                    [self.nextAction setTitle:@"Send" forState:UIControlStateNormal];
                    [self.nextAction addTarget:self action:@selector(send:) forControlEvents:UIControlEventTouchUpInside];
                }
                break;
                
            case Unknown:
                self.myImage = [aChallenge imageForPlayer:Challenger forRound:aChallenge.currentRoundNumber];
                self.otherUserImage = [aChallenge imageForPlayer:Challengee forRound:aChallenge.currentRoundNumber];
                break;
        }
    }];
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
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)send:(id)sender
{
    [self.theChallenge save];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
