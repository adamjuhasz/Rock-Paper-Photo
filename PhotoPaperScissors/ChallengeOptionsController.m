//
//  ChallengeListController.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/15/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "ChallengeOptionsController.h"
#include <Parse/Parse.h>
#include "Challenge.h"
#import "CameraController.h"

@implementation ChallengeOptionsController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    PFConfig *current = [PFConfig currentConfig];
    challenges = [current objectForKey:@"Challenges"];
    if (challenges == nil) {
        challenges = @[@"Party like a rockstar", @"Live like a moviestar", @"Get laid before prom"];
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return challenges.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"target"];
    cell.textLabel.text = challenges[indexPath.row];
    
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showCamera"]) {
        UITableViewCell *cell = (UITableViewCell*)sender;
        CameraController *controller = (CameraController*)segue.destinationViewController;
        
        Challenge *newChallenge = [[Challenge alloc] init];
        newChallenge.challengeName = cell.textLabel.text;
        newChallenge.challenger = [PFUser currentUser];
        newChallenge.challengee = self.challengee;
        newChallenge.currentRoundNumber = 1;
        
        controller.theChallenge = newChallenge;
    }
}

@end
