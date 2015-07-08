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
#import <Colours/Colours.h>

#import "CurrentChallengesController.h"
#import "FriendCollectionController.h"

@interface MainTabBarController () <PFLogInViewControllerDelegate>

@end

@implementation MainTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [[NSNotificationCenter defaultCenter] addObserverForName:@"ZeroChallenges" object:nil queue:nil usingBlock:^(NSNotification *note) {
        UIViewController *selectedController = self.selectedViewController;
        if ([selectedController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *nav = (UINavigationController*)selectedController;
            selectedController = nav.topViewController;
        }
        if ([selectedController isMemberOfClass:[CurrentChallengesController class]]) {
            for (UIViewController *controller in self.viewControllers) {
                UIViewController *potentialController = controller;
                if ([controller isKindOfClass:[UINavigationController class]]) {
                    UINavigationController *nav = (UINavigationController*)controller;
                    potentialController = nav.topViewController;
                }
                if ([potentialController isMemberOfClass:[FriendCollectionController class]]) {
                    [self setSelectedViewController:controller];
                    break;
                }
            }
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    UITabBar *tabBar = self.tabBar;
    
    UITabBarItem *item0 = [tabBar.items objectAtIndex:0];
    UITabBarItem *item1 = [tabBar.items objectAtIndex:1];
    UITabBarItem *item2 = [tabBar.items objectAtIndex:2];
    UITabBarItem *item3 = [tabBar.items objectAtIndex:3];
    
    [item0 setImage:[[UIImage imageNamed:@"Challenges"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    [item1 setImage:[[UIImage imageNamed:@"Friends"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    [item2 setImage:[[UIImage imageNamed:@"Completed"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    [item3 setImage:[[UIImage imageNamed:@"You"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    
    [[UITabBar appearance] setTintColor:[UIColor colorFromHexString:@"#6F70FF"]];
    [[UIBarButtonItem appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([PFUser currentUser] == nil) {
        
        [self performSegueWithIdentifier:@"presentSignUp" sender:self];
    } else {
        NSLog(@"logged in as \"%@\" with username:\"%@\"", [[PFUser currentUser] objectForKey:@"nickname"], [[PFUser currentUser] username]);
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
