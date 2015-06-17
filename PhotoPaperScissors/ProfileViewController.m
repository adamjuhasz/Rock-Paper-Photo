//
//  ProfileViewController.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/16/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "ProfileViewController.h"
#import <NYXImagesKit/UIImage+Resizing.h>
#import <Parse/Parse.h>

#import "PFAnalytics+PFAnalytics_TrackError.h"

@interface ProfileViewController () <UIImagePickerControllerDelegate>

@end

@implementation ProfileViewController

- (void)viewDidLoad
{
    self.profileImage.contentMode = UIViewContentModeScaleAspectFill;
    
    PFUser *currentUser = [PFUser currentUser];
    self.profileImage.file = currentUser[@"image"];
    self.username.text = currentUser[@"username"];
}

- (IBAction)getNewImage:(id)sender
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.delegate = (id)self;
    [self presentViewController:imagePickerController animated:YES completion:nil];

}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //You can retrieve the actual UIImage
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    UIImage *normalized = [[image scaleToCoverSize:CGSizeMake(300, 300)] cropToSize:CGSizeMake(300, 300) usingMode:NYXCropModeBottomCenter];
    self.profileImage.image = normalized;
    
    NSData *data = UIImageJPEGRepresentation(normalized, 0.9);
    PFFile *parseImage = [PFFile fileWithName:@"image.jpg" data:data contentType:@"image/jpeg"];
    [[PFUser currentUser] setObject:parseImage forKey:@"image"];
    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *PF_NULLABLE_S error){
        if (error) {
            [PFAnalytics trackErrorIn:@"imagePickerController" withComment:@"saveInBackgroundWithBlock" withError:error];
            return;
        }
    }];
    
    [picker dismissViewControllerAnimated:YES completion:^{
        
    }];
}

@end
