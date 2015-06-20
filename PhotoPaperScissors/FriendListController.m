//
//  FriendListController.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/15/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "FriendListController.h"

#import <Parse/Parse.h>
#import <Flow/Flow.h>
#import <DigitsKit/DigitsKit.h>
#import <MessageUI/MessageUI.h>

#import "FriendCell.h"
#import "ChallengeThemeController.h"
#import "PFUser+findFacebookFriends.h"
#import "PFAnalytics+PFAnalytics_TrackError.h"
#import "PFUser+MakeFriendships.h"

#define FriendsTutorial_ZerCount @"io.ajuhasz.friends.find"

@interface FriendListController () <UIActionSheetDelegate, UIAlertViewDelegate, MFMessageComposeViewControllerDelegate>
{
    UIBarButtonItem *find;
    UIBarButtonItem *search;
}
@end

@implementation FriendListController

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
    self.parseClassName = @"Relationship";
    
    // The key of the PFObject to display in the label of the default cell style
    self.textKey = @"text";
    
    // Whether the built-in pull-to-refresh is enabled
    self.pullToRefreshEnabled = YES;
    
    // Whether the built-in pagination is enabled
    self.paginationEnabled = YES;
    
    // The number of objects to show per page
    self.objectsPerPage = 25;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"userLoggedIn" object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self loadObjects];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"newFriendsip" object:nil queue:nil usingBlock:^(NSNotification *note) {
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
    self.title = @"Friends";
    find = [[UIBarButtonItem alloc] initWithTitle:@"Find"
                                                             style:self.editButtonItem.style
                                                            target:self
                                                            action:@selector(showSheet)];
    search = [[UIBarButtonItem alloc] initWithTitle:@"Search"
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(showSheet)];
    search.enabled = NO;
    self.navigationItem.rightBarButtonItems = @[find];
    self.navigationItem.leftBarButtonItems = @[search];
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
    // This method is called every time objects are loaded from Parse via the PFQuery
    if (self.objects.count == 0) {
        __weak typeof(self) weakSelf = self;
        [[FLWTutorialController sharedInstance] scheduleTutorialWithIdentifier:FriendsTutorial_ZerCount
                                                                    afterDelay:2.0
                                                                 withPredicate:NULL
                                                             constructionBlock:^(id<FLWTutorial> tutorial) {
                                                                 __strong typeof(self) strongSelf = weakSelf;
                                                                 tutorial.title = @"Now lets find which of your friends are already playing. Click Find.";
                                                                 tutorial.successMessage = @"Great!";
                                                                 tutorial.speechSynthesisesDisabled = NO;
                                                                 tutorial.position = FLWTutorialPositionBottom;
                                                                 //self.navigationController.navigationBar.topItem.rightBarButtonItems[0].
                                                                 //tutorial.gesture = [[FLWTapGesture alloc] initWithTouchPoint:CGPointMake(CGRectGetMidX(find.bounds), CGRectGetMidY(find.bounds)) inView:find];
                                                             }];
    }
    
    [[FLWTutorialController sharedInstance] completeTutorialWithIdentifier:FriendsTutorial_ZerCount];
    
    [super objectsDidLoad:error];
}


 // Override to customize what kind of query to perform on the class. The default is to query for
 // all objects ordered by createdAt descending.
- (PFQuery *)queryForTable {
     if ([PFUser currentUser] == nil)
     {
         return nil;
     }
     
     PFQuery *meQuery = [PFQuery queryWithClassName:self.parseClassName];
     [meQuery whereKey:@"user" equalTo:[PFUser currentUser]];
     
     PFQuery *themQuery = [PFQuery queryWithClassName:self.parseClassName];
     [themQuery whereKey:@"friendsWith" equalTo:[PFUser currentUser]];
     
     PFQuery *fullQuery = [PFQuery orQueryWithSubqueries:@[meQuery, themQuery]];
     
     
    // If Pull To Refresh is enabled, query against the network by default.
    if (self.pullToRefreshEnabled) {
        fullQuery.cachePolicy = kPFCachePolicyNetworkOnly;
    }

    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if (self.objects.count == 0) {
        fullQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
     [fullQuery includeKey:@"friendsWith"];
     [fullQuery includeKey:@"user"];
     [fullQuery orderByDescending:@"nickname"];
     
    return fullQuery;
 }



 // Override to customize the look of a cell representing an object. The default is to display
 // a UITableViewCellStyleDefault style cell with the label being the textKey in the object,
 // and the imageView being the imageKey in the object.
 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
     static NSString *CellIdentifier = @"friendCell";
 
     FriendCell *cell = (FriendCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
 
     // Configure the cell
     PFUser *user = object[@"user"];
     PFUser *friendsWith = object[@"friendsWith"];
     
     PFUser *current = [PFUser currentUser];
     PFUser *friend = nil;
     if ([current.objectId isEqualToString:user.objectId]) {
         friend = friendsWith;
     } else {
         friend = user;
     }
     
     cell.friendName.text = friend[@"nickname"];
     cell.friendPhoto.file = friend[@"image"];
     [cell.friendPhoto loadInBackground];
     
     return cell;
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
         UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Delete this friendship?"
                                                                                  message:@"Do you no longer want to be friends?"
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
    
    [self performSegueWithIdentifier:@"showChallanges" sender:self.objects[[indexPath indexAtPosition:1]]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showChallanges"]) {
        PFObject *object = (PFObject*)sender;
        ChallengeThemeController *controller = (ChallengeThemeController*)segue.destinationViewController;
        
        PFUser *friend = object[@"friendsWith"];
        controller.challengee = friend;
    }
}

- (void)showSheet
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Find friends through"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Facebook", @"Contacts", nil];
    
    actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [PFUser findFacebookFriends];
        return;
    } else if (buttonIndex == 1) {
        if ([[Digits sharedInstance] session]) {
            [self loadContactsWithDigitsSession:[[Digits sharedInstance] session]];
            return;
        }
        
        [[Digits sharedInstance] authenticateWithTitle:@"Rock Paper Photo" completion:^(DGTSession *session, NSError *error) {
            if (error) {
                NSLog(@"Error with authenticate: %@", error);
                [PFAnalytics trackErrorIn:NSStringFromSelector(_cmd) withComment:@"authenticateWithTitle" withError:error];
                return;
            }
            
            if (session) {
                [[PFUser currentUser] setObject:session.phoneNumber forKey:@"phoneNumber"];
                [[PFUser currentUser] setObject:session.userID forKey:@"DigitID"];
                [[PFUser currentUser] setObject:session.authToken forKey:@"DigitAuthToken"];
                [[PFUser currentUser] setObject:session.authTokenSecret forKey:@"DigitAuthTokenSecret"];
                [[PFUser currentUser] saveInBackground];
                
                [self loadContactsWithDigitsSession:session];
            }
        }];
    }
}

- (void)loadContactsWithDigitsSession:(DGTSession*)session
{
    DGTContacts *friendFinder = [[DGTContacts alloc] initWithUserSession:session];
    [friendFinder startContactsUploadWithTitle:@"Rock Paper Photo" completion:^(DGTContactsUploadResult *result, NSError *error) {
        if (error) {
            NSLog(@"Error with startContactsUploadWithTitle: %@", error);
            [PFAnalytics trackErrorIn:NSStringFromSelector(_cmd) withComment:@"startContactsUploadWithTitle" withError:error];
            return;
        }
        
        [friendFinder lookupContactMatchesWithCursor:nil completion:^(NSArray *matches, NSString *nextCursor, NSError *error) {
            if (error) {
                NSLog(@"Error with lookupContactMatchesWithCurso: %@", error);
                [PFAnalytics trackErrorIn:NSStringFromSelector(_cmd) withComment:@"lookupContactMatchesWithCursor" withError:error];
                return;
            }
            
            NSLog(@"matches: %@", matches);
            PFQuery *userQuery = [PFUser query];
            [userQuery whereKey:@"DigitID" containedIn:matches];
            [PFUser AJMakeFriendsWithUsersWithQuery:userQuery
                                     withCompletion:^(NSNumber *count) {
                                         [self alertToDigitsCount:count.integerValue];
            }];
        }];
    }];
}

- (void)alertToDigitsCount:(NSInteger)count
{
    NSString *string = [NSString stringWithFormat:@"Found %ld new friends through Facebook", (long)count];
    UIAlertView *alerting = [[UIAlertView alloc] initWithTitle:@"Contacts"
                                                       message:string
                                                      delegate:self
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:@"Invite More", nil];
    [alerting show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        if(![MFMessageComposeViewController canSendText]) {
            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your device doesn't support SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [warningAlert show];
            return;
        }
        
        MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
        NSString *mesageString = [NSString stringWithFormat:@"Try out Rock Paper Photos! %@", @"http://appstore.link"];
        [messageController setBody:mesageString];
        
        messageController.messageComposeDelegate = self;
        [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:messageController animated:YES completion:nil];
    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [[[[UIApplication sharedApplication] keyWindow] rootViewController] dismissViewControllerAnimated:YES completion:nil];
}


@end
