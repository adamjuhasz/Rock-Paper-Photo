//
//  ChallengeTheme.h
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/18/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import <UIKit/UIKit.h>

@interface ChallengeTheme : NSObject

@property NSString *name;

@property UIImage *coverphoto;
@property PFFile *coverphotoFile;

@property UIImage *thumbnail;
@property PFFile *thumbnailFile;

@property UIImage *template1;
@property PFFile *template1File;

@property UIImage *template2;
@property PFFile *template2File;

@property UIImage *template3;
@property PFFile *template3File;

- (id)initWithParseObject:(PFObject*)object;

@end
