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
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    if (functionName) {
        [dict setObject:functionName forKey:@"Source"];
    }
    if (comment) {
        [dict setObject:comment forKey:@"info"];
    }
    if (error) {
        [dict setObject:[error description] forKey:@"error"];
    }
    
    if (dict.allKeys.count == 0) {
        [PFAnalytics trackEventInBackground:@"Error" block:nil];
    } else {
        [PFAnalytics trackEventInBackground:@"Error" dimensions:dict block:nil];
    }
    
}

@end
