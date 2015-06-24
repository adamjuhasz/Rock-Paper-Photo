//
//  CurrentChallengesController.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/16/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "CurrentChallengesController.h"

#import <Colours/Colours.h>

#import "ChallengeCell.h"
#import "CameraController.h"
#import "PhotoViewController.h"

@implementation CurrentChallengesController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
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

- (void)commonInit
{
    // The className to query on
    self.parseClassName = @"Challenge";
    
    // Whether the built-in pull-to-refresh is enabled
    self.pullToRefreshEnabled = YES;
    
    // Whether the built-in pagination is enabled
    self.paginationEnabled = YES;
    
    // The number of objects to show per page
    self.objectsPerPage = 25;
    
    [self setUpNotifications];
}

- (void)setUpNotifications
{
    [[NSNotificationCenter defaultCenter] addObserverForName:@"userLoggedIn" object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self loadObjects];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"updateChallanges" object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self loadObjects];
    }];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    //self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 10, 0);
    
    self.navigationItem.title = @"Current Challenges";
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@" "
                                                                             style:self.navigationItem.backBarButtonItem.style
                                                                            target:nil
                                                                            action:nil];
    
    gradientStartColor = [UIColor colorFromHexString:@"#6F70FF"];
    gradientEndColor = [UIColor colorFromHexString:@"#33CABA"];
    
    gradientStartColorArray = [gradientStartColor CIE_LCHArray];
    gradientEndColorArray = [gradientEndColor CIE_LCHArray];
    
    self.navigationController.navigationBar.barTintColor = [gradientStartColor darken:0.25];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.translucent = NO;
    self.view.backgroundColor = [gradientStartColor darken:0.1];
    self.tableView.backgroundColor = self.view.backgroundColor;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ChallengeCell" bundle:nil] forCellReuseIdentifier:@"xib"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ChallengeModernCell" bundle:nil] forCellReuseIdentifier:@"modern"];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - PFQueryTableViewController

- (void)objectsWillLoad {
    [super objectsWillLoad];
    
    // This method is called before a PFQuery is fired to get more objects
}

// This method is called every time objects are loaded from Parse via the PFQuery
- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    
    if (self.objects.count == 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ZeroChallenges" object:nil];
    }
    
    if ([self isMemberOfClass:[CurrentChallengesController class]]) {
        PFInstallation *badging = [PFInstallation currentInstallation];
        badging.badge = 0;
        for (int i=0; i<self.objects.count; i++) {
            Challenge *thisChallenge = [Challenge challengeForParseObject:self.objects[i]];
            if (thisChallenge.whosTurn == myTurn) {
                badging.badge++;
            }
            if (thisChallenge.whosTurn == noonesTurn) {
                badging.badge++;
            }
        }
        UITabBarItem *myItem = self.tabBarController.tabBar.items[0];
        myItem.badgeValue = [NSString stringWithFormat:@"%ld", (long)badging.badge];
    }
}


// Override to customize what kind of query to perform on the class. The default is to query for
// all objects ordered by createdAt descending.
- (PFQuery *)queryForTable {
    if ([PFUser currentUser] == nil) {
        NSLog(@"no logged in user");
        return nil;
    }
    
    PFQuery *challengeeQuery = [PFQuery queryWithClassName:self.parseClassName];
    [challengeeQuery whereKey:@"challengee" equalTo:[PFUser currentUser]];
    
    PFQuery *challengerQuery = [PFQuery queryWithClassName:self.parseClassName];
    [challengerQuery whereKey:@"createdBy" equalTo:[PFUser currentUser]];
    
    PFQuery *fullQuery = [PFQuery orQueryWithSubqueries:@[challengerQuery, challengeeQuery]];
    [fullQuery includeKey:@"challengee"];
    [fullQuery includeKey:@"createdBy"];
    [fullQuery includeKey:@"theme"];
    [fullQuery whereKey:@"completed" equalTo:@(NO)];
    [fullQuery orderByDescending:@"createdAt"];
    
    // If Pull To Refresh is enabled, query against the network by default.
    if (self.pullToRefreshEnabled) {
        fullQuery.cachePolicy = kPFCachePolicyNetworkOnly;
    }
    
    return fullQuery;
}

- (UIColor*)colorForCellPosition:(NSIndexPath *)path
{
    NSInteger i = [path row];
    int steps = (int)(MAX(self.objects.count, MinimumGradientSteps));
    
    double L = ([gradientEndColorArray[0] doubleValue] - [gradientStartColorArray[0] doubleValue]) / (steps-1) * i + [gradientStartColorArray[0] doubleValue];
    double C = ([gradientEndColorArray[1] doubleValue] - [gradientStartColorArray[1] doubleValue]) / (steps-1) * i + [gradientStartColorArray[1] doubleValue];
    double H = ([gradientEndColorArray[2] doubleValue] - [gradientStartColorArray[2] doubleValue]) / (steps-1) * i + [gradientStartColorArray[2] doubleValue];
    double A = ([gradientEndColorArray[3] doubleValue] - [gradientStartColorArray[3] doubleValue]) / (steps-1) * i + [gradientStartColorArray[3] doubleValue];
    
    UIColor *diffColor = [UIColor colorFromCIE_LCHArray:@[@(L), @(C), @(H), @(A)]];
    return diffColor;
}

// Override to customize the look of a cell representing an object. The default is to display
// a UITableViewCellStyleDefault style cell with the label being the textKey in the object,
// and the imageView being the imageKey in the object.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *CellIdentifier = @"modern";
    
    ChallengeCell *cell = (ChallengeCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell
    Challenge *newChallenge = [Challenge challengeForParseObject:object];
    [cell loadWithChallenge:newChallenge];
    
    cell.backgroundColor = [self colorForCellPosition:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    // Add your Colour.
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.backgroundColor = [[self colorForCellPosition:indexPath] lighten:0.3];
}


- (void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    // Reset Colour.
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.backgroundColor = [self colorForCellPosition:indexPath];
}

/*
 // Override if you need to change the ordering of objects in the table.
 - (PFObject *)objectAtIndex:(NSIndexPath *)indexPath {
 return [self.objects objectAtIndex:indexPath.row];
 }
 */

/*
 // Override to customize the look of the cell that allows the user to load the next page of objects.
 // The default implementation is a UITableViewCellStyleDefault cell with simple labels.
 - (UITableViewCell *)tableView:(UITableView *)tableView cellForNextPageAtIndexPath:(NSIndexPath *)indexPath {
 static NSString *CellIdentifier = @"NextPage";
 
 UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
 
 if (cell == nil) {
 cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
 }
 
 cell.selectionStyle = UITableViewCellSelectionStyleNone;
 cell.textLabel.text = @"Load more...";
 
 return cell;
 }
 */

#pragma mark - UITableViewDataSource


 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
     // Return NO if you do not want the specified item to be editable.
     return YES;
 }



 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
     if (editingStyle == UITableViewCellEditingStyleDelete) {
         // Delete the object from Parse and reload the table view
         UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Delete this challenge?"
                                                                                  message:@"Do you want to stop playing this challenge? This will delete the challenge and can not be undone."
                                                                           preferredStyle:UIAlertControllerStyleAlert];
         
         [alertController addAction:[UIAlertAction actionWithTitle:@"Delete"
                                                             style:UIAlertActionStyleDestructive
                                                           handler:^(UIAlertAction *action) {
                                                               [self removeObjectAtIndexPath:indexPath];
                                                           }]];
         
         [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                             style:UIAlertActionStyleCancel
                                                           handler:^(UIAlertAction *action) {
                                                               [self setEditing:NO animated:YES];
                                                           }]];
         
         [self presentViewController:alertController animated:YES completion:nil];
     } else if (editingStyle == UITableViewCellEditingStyleInsert) {
         // Create a new instance of the appropriate class, and save it to Parse
     }
 }


/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    
    PFObject *object = [self.objects objectAtIndex:indexPath.row];
    Challenge *newChallenge = [Challenge challengeForParseObject:object];
    
    if (newChallenge.currentRoundNumber == 1 && newChallenge.playerIAm != Challenger && newChallenge.photoSent == NO) {
        [self performSegueWithIdentifier:@"showCamera" sender:newChallenge];
    } else {
        [self performSegueWithIdentifier:@"showPhotos" sender:newChallenge];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    Challenge *challenge = (Challenge*)sender;
    
    if ([segue.identifier isEqualToString:@"showCamera"]) {
        CameraController *controller = (CameraController*)segue.destinationViewController;
        controller.theChallenge = challenge;
    }
    if ([segue.identifier isEqualToString:@"showPhotos"]) {
        PhotoViewController *controller = (PhotoViewController*)segue.destinationViewController;
        controller.theChallenge = challenge;
    }
}

@end