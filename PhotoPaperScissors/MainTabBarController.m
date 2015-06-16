//
//  ViewController.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/14/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "MainTabBarController.h"
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>

@interface MainTabBarController () <PFLogInViewControllerDelegate>

@end

@implementation MainTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([PFUser currentUser] == nil) {
        PFLogInViewController *logInViewController = [[PFLogInViewController alloc] init];
        logInViewController.fields = (PFLogInFieldsUsernameAndPassword
                                  | PFLogInFieldsLogInButton
                                  | PFLogInFieldsSignUpButton
                                  | PFLogInFieldsFacebook
                                  | PFLogInFieldsTwitter
                                  | PFLogInFieldsDismissButton);
        logInViewController.delegate = self;
        PFSignUpViewController *signup = logInViewController.signUpController;
        signup.fields = PFSignUpFieldsUsernameAndPassword |
        PFSignUpFieldsSignUpButton;
                                    //| PFSignUpFieldsDismissButton;
        
        [self presentViewController:logInViewController animated:YES completion:nil];

    } else {
        NSLog(@"logged in as \"%@\"", [[PFUser currentUser] username]);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)logInViewController:(PFLogInViewController * __nonnull)logInController didLogInUser:(PFUser * __nonnull)user
{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"userLoggedIn" object:nil];
}

@end
