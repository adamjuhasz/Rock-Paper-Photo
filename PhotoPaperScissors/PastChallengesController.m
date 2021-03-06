//
//  PastChallengesController.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/18/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "PastChallengesController.h"

#import <Colours/Colours.h>

#import "ChallengeCell.h"
#import "ChallengeModernCell.h"

@interface PastChallengesController ()
{

}

@end

@implementation PastChallengesController

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
    self.navigationItem.title = @"Completed Challenges";
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

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    
    // This method is called every time objects are loaded from Parse via the PFQuery
}


// Override to customize what kind of query to perform on the class. The default is to query for
// all objects ordered by createdAt descending.
- (PFQuery *)queryForTable {    
     //PFQuery *fullQuery = [PFQuery queryWithClassName:self.parseClassName];
    PFQuery *fullQuery = [super queryForTable];
     [fullQuery whereKey:@"completed" equalTo:@(YES)];
    
    fullQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
     return fullQuery;
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

/*
 // Override if you need to change the ordering of objects in the table.
 - (PFObject *)objectAtIndex:(NSIndexPath *)indexPath {
 return [self.objects objectAtIndex:indexPath.row];
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
                                                                                  message:@"This can not be undone."
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


@end
