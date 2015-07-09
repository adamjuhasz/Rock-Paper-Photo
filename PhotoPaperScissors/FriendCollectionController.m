//
//  FriendCollectionController.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/20/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "FriendCollectionController.h"
#import <Parse/Parse.h>
#import <DigitsKit/DigitsKit.h>
#import <MessageUI/MessageUI.h>
#import <Colours/Colours.h>
#import <Flow/FLWTutorialController.h>
#import <Flow/FLWTapGesture.h>
#import <ClusterPrePermissions/ClusterPrePermissions.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FriendCollectionCell.h"
#import "ChallengeThemeController.h"

#import "PFAnalytics+PFAnalytics_TrackError.h"
#import "PFUser+findFacebookFriends.h"
#import "PFUser+MakeFriendships.h"

static NSString * const FindFriendsTutorialString = @"io.ajuhasz.friends.find";

@interface FriendCollectionController () <MFMessageComposeViewControllerDelegate, UIActionSheetDelegate>

@end

@implementation FriendCollectionController

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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.title = @"Friends";
    UIBarButtonItem *find = [[UIBarButtonItem alloc] initWithTitle:@"Find"
                                            style:UIBarButtonItemStyleDone
                                           target:self
                                           action:@selector(showSheet)];
    self.navigationItem.rightBarButtonItems = @[find];
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"FriendCollectionCell" bundle:nil] forCellWithReuseIdentifier:@"friendlies"];
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout*)self.collectionViewLayout;
    layout.minimumInteritemSpacing = 10;
    int friendsPerLine = 2;
    layout.minimumLineSpacing = layout.minimumInteritemSpacing;
    layout.sectionInset = UIEdgeInsetsMake(layout.minimumInteritemSpacing, layout.minimumInteritemSpacing, layout.minimumInteritemSpacing, layout.minimumInteritemSpacing);
    CGFloat width = (self.view.bounds.size.width - (layout.sectionInset.left + layout.sectionInset.right) - (friendsPerLine-1)*layout.minimumInteritemSpacing) / friendsPerLine;
    layout.itemSize = CGSizeMake(width, width * layout.itemSize.height / layout.itemSize.width);
    
    UIColor *startColor = [UIColor colorFromHexString:@"#6F70FF"];
    UIColor *endColor = [UIColor colorFromHexString:@"#33CABA"];
    
    self.navigationController.navigationBar.barTintColor = [startColor darken:0.25];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.translucent = NO;
    
    UIView *background = [[UIView alloc] initWithFrame:self.collectionView.bounds];
    self.collectionView.backgroundView = background;
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = background.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[startColor CGColor], (id)[endColor CGColor], nil];
    [background.layer insertSublayer:gradient atIndex:0];
}

- (void)objectsDidLoad:(nullable NSError *)error
{
    [super objectsDidLoad:error];
    
    [[FLWTutorialController sharedInstance] completeTutorialWithIdentifier:FindFriendsTutorialString];
    if (self.objects.count == 0) {
        [[FLWTutorialController sharedInstance] resetTutorialWithIdentifier:FindFriendsTutorialString];
        [[FLWTutorialController sharedInstance] scheduleTutorialWithIdentifier:FindFriendsTutorialString
                                                                    afterDelay:1.0
                                                                 withPredicate:NULL
                                                             constructionBlock:^(id<FLWTutorial> tutorial) {
                                                                 tutorial.title = @"Why don't we find some friends to challenge?";
                                                                 tutorial.speechSynthesisesDisabled = NO;
                                                                 tutorial.position = FLWTutorialPositionBottom;
                                                                 tutorial.gesture =  [[FLWTapGesture alloc] initWithTouchPoint:CGPointMake(self.view.bounds.size.width - 28, 44) inView:self.navigationController.view];
                                                                 tutorial.respectsSilentSwitch = YES;
                                                             }];
    } else if (self.objects.count <= 4) {
        int friendsPerLine = 2;
        UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout*)self.collectionViewLayout;
        CGFloat width = (self.view.bounds.size.width - (layout.sectionInset.left + layout.sectionInset.right) - (friendsPerLine-1)*layout.minimumInteritemSpacing) / friendsPerLine;
        layout.itemSize = CGSizeMake(width, width * layout.itemSize.height / layout.itemSize.width);
    } else {
        int friendsPerLine = 3;
        UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout*)self.collectionViewLayout;
        CGFloat width = (self.view.bounds.size.width - (layout.sectionInset.left + layout.sectionInset.right) - (friendsPerLine-1)*layout.minimumInteritemSpacing) / friendsPerLine;
        layout.itemSize = CGSizeMake(width, width * layout.itemSize.height / layout.itemSize.width);
    }
}

- (PFQuery *)queryForCollection {
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

- (PFUI_NULLABLE PFCollectionViewCell *)collectionView:(UICollectionView *)collectionView
                                cellForItemAtIndexPath:(NSIndexPath *)indexPath
                                                object:(PFUI_NULLABLE PFObject *)object;
{
    FriendCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"friendlies" forIndexPath:indexPath];
    
    PFUser *user = object[@"user"];
    PFUser *friendsWith = object[@"friendsWith"];
    
    PFUser *current = [PFUser currentUser];
    PFUser *friend = nil;
    if ([current.objectId isEqualToString:user.objectId]) {
        friend = friendsWith;
    } else {
        friend = user;
    }
    
    if (friend.isDataAvailable == NO) {

    } else {
        cell.nickname.text = friend[@"nickname"];
        cell.profileImageView.file = friend[@"image"];
        [cell.profileImageView loadInBackground];
    }
    
    return cell;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"showChallanges" sender:self.objects[[indexPath indexAtPosition:1]]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showChallanges"]) {
        PFObject *object = (PFObject*)sender;
        ChallengeThemeController *controller = (ChallengeThemeController*)segue.destinationViewController;
        
        PFUser *user = object[@"user"];
        PFUser *friendsWith = object[@"friendsWith"];
        PFUser *current = [PFUser currentUser];
        
        PFUser *friend = nil;
        if ([current.objectId isEqualToString:user.objectId]) {
            friend = friendsWith;
        } else {
            friend = user;
        }
        controller.challengee = friend;
    }
}

- (void)showSheet
{
    [[FLWTutorialController sharedInstance] completeTutorialWithIdentifier:FindFriendsTutorialString];
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
    
    ClusterPrePermissions *permission = [ClusterPrePermissions sharedPermissions];
    [permission showPushNotificationPermissionsWithType:UIUserNotificationTypeAlert | UIUserNotificationTypeSound | UIUserNotificationTypeBadge
                                                  title:@"Want to know when your friends join?"
                                                message:@"Want us to let you know when a friend of yours joins?"
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
            [self alertToDigitsCount:0];
            return;
        }
        
        
        [friendFinder lookupContactMatchesWithCursor:nil completion:^(NSArray *matches, NSString *nextCursor, NSError *error) {
            if (error) {
                NSLog(@"Error with lookupContactMatchesWithCurso: %@", error);
                [PFAnalytics trackErrorIn:NSStringFromSelector(_cmd) withComment:@"lookupContactMatchesWithCursor" withError:error];
                [self alertToDigitsCount:0];
                return;
            }
            
            NSMutableArray *digitIds = [NSMutableArray array];
            for (DGTUser *user in matches) {
                [digitIds addObject:user.userID];
            }
            PFQuery *userQuery = [PFUser query];
            [userQuery whereKey:@"DigitID" containedIn:digitIds];
            [PFUser AJMakeFriendsWithUsersWithQuery:userQuery
                                     source:@"digits"
                                     withCompletion:^(NSNumber *count) {
                                         [self alertToDigitsCount:count.integerValue];
                                     }];
        }];
    }];
}

- (void)alertToDigitsCount:(NSInteger)count
{
    NSString *string = [NSString stringWithFormat:@"Found %ld new friends in your contacts", (long)count];
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
        NSString *mesageString = [NSString stringWithFormat:@"Try out Rock Paper Photos! %@", @"http://rockpaperphoto.me"];
        [messageController setBody:mesageString];
        
        messageController.messageComposeDelegate = self;
        [self.tabBarController presentViewController:messageController animated:YES completion:nil];
    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [[[[UIApplication sharedApplication] keyWindow] rootViewController] dismissViewControllerAnimated:YES completion:nil];
}




@end
