//
//  PFAnalytics+PFAnalytics_TrackError.h
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/16/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import <Parse/Parse.h>

@interface PFAnalytics (PFAnalytics_TrackError)

+ (void)trackErrorIn:(NSString*)string withComment:(NSString*)string withError:(NSError*)error;

@end
