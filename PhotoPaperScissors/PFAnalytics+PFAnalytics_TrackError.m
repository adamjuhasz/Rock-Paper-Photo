//
//  PFAnalytics+PFAnalytics_TrackError.m
//  PhotoPaperScissors
//
//  Created by Adam Juhasz on 6/16/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "PFAnalytics+PFAnalytics_TrackError.h"

@implementation PFAnalytics (PFAnalytics_TrackError)

+ (void)trackErrorIn:(NSString*)functionName withComment:(NSString*)comment withError:(NSError*)error
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          functionName, @"Source",
                          comment, @"info",
                          error, @"error", nil];
    
    [PFAnalytics trackEventInBackground:@"Error" dimensions:dict block:nil];
}

@end
