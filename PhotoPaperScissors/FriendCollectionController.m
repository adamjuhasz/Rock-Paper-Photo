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
#import <Crashlytics/Answers.h>
#import <FBSDKShareKit/FBSDKShareKit.h>
#import <Crashlytics/Answers.h>
#import <Google/AppInvite.h>
#import <Google/SignIn.h>

#import "FriendCollectionCell.h"
#import "ChallengeThemeController.h"

#import "PFAnalytics+PFAnalytics_TrackError.h"
#import "PFUser+findFacebookFriends.h"
#import "PFUser+MakeFriendships.h"

static NSString * const FindFriendsTutorialString = @"io.ajuhasz.friends.find";
static NSString * const InviteFriendsTutorialString = @"io.ajuhasz.friends.invite";

@interface FriendCollectionController () <MFMessageComposeViewControllerDelegate, UIActionSheetDelegate, FBSDKAppInviteDialogDelegate, GINInviteDelegate, GIDSignInUIDelegate, GIDSignInDelegate>

@property id <GINInviteBuilder> inviteDialog;

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
    self.objectsPerPage = 100;
    
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
    
    UIBarButtonItem *invite = [[UIBarButtonItem alloc] initWithTitle:@"Invite"
                                                               style:UIBarButtonItemStyleDone
                                                              target:self
                                                              action:@selector(showInvite)];
    self.navigationItem.leftBarButtonItems = @[invite];
    
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[FLWTutorialController sharedInstance] scheduleTutorialWithIdentifier:FindFriendsTutorialString
                                                                afterDelay:1.0
                                                             withPredicate:NULL
                                                         constructionBlock:^(id<FLWTutorial> tutorial) {
                                                             tutorial.title = @"Let's find some friends to challenge";
                                                             tutorial.speechSynthesisesDisabled = NO;
                                                             tutorial.position = FLWTutorialPositionBottom;
                                                             tutorial.gesture =  [[FLWTapGesture alloc] initWithTouchPoint:CGPointMake(self.view.bounds.size.width - 28, 44) inView:self.navigationController.view];
                                                             tutorial.respectsSilentSwitch = YES;
                                                         }];
    
    [[FLWTutorialController sharedInstance] scheduleTutorialWithIdentifier:InviteFriendsTutorialString
                                                                afterDelay:1.0
                                                             withPredicate:NULL
                                                         constructionBlock:^(id<FLWTutorial> tutorial) {
                                                             tutorial.title = @"Let's invite some friends to challenge";
                                                             tutorial.speechSynthesisesDisabled = NO;
                                                             tutorial.position = FLWTutorialPositionBottom;
                                                             tutorial.gesture =  [[FLWTapGesture alloc] initWithTouchPoint:CGPointMake(28, 44) inView:self.navigationController.view];
                                                             tutorial.respectsSilentSwitch = YES;
                                                             tutorial.dependentTutorialIdentifiers = @[FindFriendsTutorialString];
                                                         }];
}

- (void)objectsDidLoad:(nullable NSError *)error
{
    [super objectsDidLoad:error];
    
    if (self.objects.count <= 4) {
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
    
    if (self.objects.count > 0) {
        
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
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if (self.objects.count == 0) {
        fullQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    [fullQuery includeKey:@"friendsWith"];
    [fullQuery includeKey:@"user"];
    [fullQuery orderByDescending:@"createdAt"];
    
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
    [Answers logCustomEventWithName:@"Select friend to challange" customAttributes:nil];
    [FBSDKAppEvents logEvent:@"Select Friend" parameters:@{FBSDKAppEventParameterNameContentType: @"challange"}];
    
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
    actionSheet.tag = 100;
    [actionSheet showInView:self.view];
    
    [Answers logCustomEventWithName:@"Show Frind Friends Sheet" customAttributes:nil];
    [FBSDKAppEvents logEvent:@"Show Frind Friends Sheet" parameters:nil];
}

- (void)showInvite
{
    [[FLWTutorialController sharedInstance] completeTutorialWithIdentifier:InviteFriendsTutorialString];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Invtite friends through"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Text", @"Facebook", @"Google", nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
    actionSheet.tag = 101;
    [actionSheet showInView:self.view];
    
    [Answers logCustomEventWithName:@"Show Invite Friends Sheet" customAttributes:nil];
    [FBSDKAppEvents logEvent:@"Show Invite Friends Sheet" parameters:nil];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (actionSheet.tag) {
        case 100:
            [self findFriendsFromButton:buttonIndex];
            break;
            
            
        case 101:
            [self inviteFriendsFromButton:buttonIndex];
            break;
            
        //no tag
        default:
            break;
    }
}
    
-(void)inviteFriendsFromButton:(NSInteger) buttonIndex
{
    switch (buttonIndex) {
        case 0:
        {
            [FBSDKAppEvents logEvent:@"Invite Friends Selected"
                          parameters:@{FBSDKAppEventParameterNameContentType: @"friends",
                                       @"source": @"sms"}];
            [Answers logInviteWithMethod:@"sms" customAttributes:@{}];
            
            if(![MFMessageComposeViewController canSendText]) {
                UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your device doesn't support SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [warningAlert show];
                return;
            }
            [[UINavigationBar appearance] setTitleTextAttributes: @{
                                                                    NSForegroundColorAttributeName : [UIColor blackColor],
                                                                    NSFontAttributeName : [UIFont fontWithName:@"Montserrat-Light" size:18.0]
                                                                    }];
            [[UIBarButtonItem appearance] setTintColor:[UIColor blackColor]];
            
            MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
            NSString *mesageString = [NSString stringWithFormat:@"Challenge me to 3 rounds of photos using Rock Paper Photo ! %@", @"http://rockpaperphoto.me"];
            [messageController setBody:mesageString];
            
            messageController.messageComposeDelegate = self;
            
            [self.tabBarController presentViewController:messageController animated:YES completion:^{
                [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
            }];
            break;
        }
        case 1:
        {
            [FBSDKAppEvents logEvent:@"inviteFriends"
                          parameters:@{FBSDKAppEventParameterNameContentType: @"friends",
                                       @"source": @"facebook"}];
            [Answers logInviteWithMethod:@"facebook" customAttributes:@{}];
            
            FBSDKAppInviteContent *content =[[FBSDKAppInviteContent alloc] init];
            content.appLinkURL = [NSURL URLWithString:@"https://fb.me/1072099979629129"];
            content.appInvitePreviewImageURL = [NSURL URLWithString:@"http://rockpaperphoto.me/invite.png"];
            
            // present the dialog. Assumes self implements protocol `FBSDKAppInviteDialogDelegate`
            [FBSDKAppInviteDialog showWithContent:content delegate:self];
        }
            break;
            
        case 2:
        {
            [FBSDKAppEvents logEvent:@"inviteFriends"
                          parameters:@{FBSDKAppEventParameterNameContentType: @"friends",
                                       @"source": @"google"}];
            [Answers logInviteWithMethod:@"google" customAttributes:@{}];
            
            if ([[GIDSignIn sharedInstance] currentUser] == nil) {
                [GIDSignIn sharedInstance].delegate = self;
                [[GIDSignIn sharedInstance] signInSilently];
                return;
            }
            
            [self showGoogleAppInvite];
        }
            break;
            
        default:
            break;
    }
}

- (void)showGoogleAppInvite
{
    self.inviteDialog = [GINInvite inviteDialog];
    [self.inviteDialog setInviteDelegate: self];
    
    // NOTE: You must have the App Store ID set in your developer console project
    // in order for invitations to successfully be sent.
    NSString* message = [NSString stringWithFormat:@"Play Rock Paper Photo with me!"];
    
    // A message hint for the dialog. Note this manifests differently depending on the
    // received invation type. For example, in an email invite this appears as the subject.
    [self.inviteDialog setMessage: message];
    
    // Title for the dialog, this is what the user sees before sending the invites.
    [self.inviteDialog setTitle: @"Invite friends"];
    [self.inviteDialog setDeepLink: @"RPPhoto://googleinvite"];
    [self.inviteDialog open];
}

- (void)inviteFinishedWithInvitations:(NSArray *)invitationIds error:(NSError *)error {
    NSString *message = error ? error.localizedDescription :
    [NSString stringWithFormat:@"%lu invites sent", (unsigned long)invitationIds.count];
    [[[UIAlertView alloc] initWithTitle:@"Done"
                                message:message
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

-(void)findFriendsFromButton:(NSInteger)buttonIndex
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
        [FBSDKAppEvents logEvent:@"Find Friends"
                      parameters:@{FBSDKAppEventParameterNameContentType: @"friends",
                                   @"source": @"facebook"}];
        [Answers logCustomEventWithName:@"Find Friends" customAttributes:@{@"source": @"facebook"}];
                                                                           
        [PFUser findFacebookFriends];
        return;
    } else if (buttonIndex == 1) {
        [FBSDKAppEvents logEvent:@"Find Friends"
                      parameters:@{FBSDKAppEventParameterNameContentType: @"friends",
                                   @"source": @"contacts"}];
        [Answers logCustomEventWithName:@"Find Friends" customAttributes:@{@"source": @"contacts"}];
                                                                           
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
    alerting.tag = 100;
    [alerting show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case 100:
            if (buttonIndex == 1) {
                [Answers logInviteWithMethod:@"sms" customAttributes:@{}];
                
                if(![MFMessageComposeViewController canSendText]) {
                    UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your device doesn't support SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [warningAlert show];
                    return;
                }
                [[UINavigationBar appearance] setTitleTextAttributes: @{
                                                                        NSForegroundColorAttributeName : [UIColor blackColor],
                                                                        NSFontAttributeName : [UIFont fontWithName:@"Montserrat-Light" size:18.0]
                                                                        }];
                [[UIBarButtonItem appearance] setTintColor:[UIColor blackColor]];
                
                MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
                NSString *mesageString = [NSString stringWithFormat:@"Try out Rock Paper Photo! %@", @"http://rockpaperphoto.me"];
                [messageController setBody:mesageString];
                
                messageController.messageComposeDelegate = self;
                
                [self.tabBarController presentViewController:messageController animated:YES completion:^{
                    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
                }];
            }
            break;
            
        case 101:
            break;
        default:
            break;
    }
    
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [[UINavigationBar appearance] setTitleTextAttributes: @{
                                                            NSForegroundColorAttributeName : [UIColor whiteColor],
                                                            NSFontAttributeName : [UIFont fontWithName:@"Montserrat-Light" size:18.0]
                                                            }];
    [[UIBarButtonItem appearance] setTintColor:[UIColor whiteColor]];
    
    [[[[UIApplication sharedApplication] keyWindow] rootViewController] dismissViewControllerAnimated:YES completion:nil];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didCompleteWithResults:(NSDictionary *)results
{
    NSLog(@"appInviteDialog: %@", results);
    NSMutableDictionary *dict = [results mutableCopy];
    [dict setObject:@"Invite Button" forKey:@"source"];
    
    [Answers logCustomEventWithName:@"Facebook Invite" customAttributes:dict];
}

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didFailWithError:(NSError *)error
{
    NSLog(@"Error with appInvite: %@", error);
    [PFAnalytics trackErrorIn:NSStringFromSelector(_cmd) withComment:nil withError:error];
    return;
}

// Implement these methods only if the GIDSignInUIDelegate is not a subclass of
// UIViewController.

// Stop the UIActivityIndicatorView animation that was started when the user
// pressed the Sign In button
- (void)signInWillDispatch:(GIDSignIn *)signIn error:(NSError *)error {

}

// Present a view that prompts the user to sign in with Google
- (void)signIn:(GIDSignIn *)signIn presentViewController:(UIViewController *)viewController {
    [[UINavigationBar appearance] setTitleTextAttributes: @{
                                                            NSForegroundColorAttributeName : [UIColor blackColor],
                                                            NSFontAttributeName : [UIFont fontWithName:@"Montserrat-Light" size:18.0]
                                                            }];
    [[UIBarButtonItem appearance] setTintColor:[UIColor blackColor]];
    
    [self presentViewController:viewController animated:YES completion:^{
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    }];
}

// Dismiss the "Sign in with Google" view
- (void)signIn:(GIDSignIn *)signIn dismissViewController:(UIViewController *)viewController {
    [[UINavigationBar appearance] setTitleTextAttributes: @{
                                                            NSForegroundColorAttributeName : [UIColor whiteColor],
                                                            NSFontAttributeName : [UIFont fontWithName:@"Montserrat-Light" size:18.0]
                                                            }];
    [[UIBarButtonItem appearance] setTintColor:[UIColor whiteColor]];
    [self dismissViewControllerAnimated:YES completion:^{
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    }];
}

- (void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user withError:(NSError *)error
{
    if (error) {
        [GIDSignIn sharedInstance].uiDelegate = self;
        [[GIDSignIn sharedInstance] signIn];
    } else {
        [self showGoogleAppInvite];
    }
}

@end
