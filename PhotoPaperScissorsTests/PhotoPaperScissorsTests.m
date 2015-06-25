//
//  PhotoPaperScissorsTests.m
//  PhotoPaperScissorsTests
//
//  Created by Adam Juhasz on 6/14/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "Challenge.h"

@interface PhotoPaperScissorsTests : XCTestCase
{
    PFObject *parseObject;
}
@end

@implementation PhotoPaperScissorsTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    parseObject = [PFObject objectWithClassName:@"Challenge"];
    parseObject[@"challengeName"] = @"hello";
    parseObject[@"maxRounds"] = @(3);
    
    /*
    PFUser *challenger = [PFUser user];
    challenger[@"nickname"] = @"challenger";
    parseObject[@"createdBy"] = challenger;
    
    PFUser *challengee = [PFUser user];
    challengee[@"nickname"] = @"challengee";
    parseObject[@"challengee"] = challengee;
     */
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testParseName {
    // This is an example of a functional test case.
    Challenge *newChallenge = [Challenge challengeForParseObject:parseObject];
    XCTAssertNotNil(newChallenge);
    XCTAssertEqual(newChallenge.challengeName, @"hello");
}

- (void)testParseNewRound {
    parseObject[@"roundNumber"] = @(2);
    parseObject[@"maxRounds"]  = @(3);
    
    parseObject[@"imageR0Challenger"] = @"";
    parseObject[@"imageR0Challenger"] = [PFFile fileWithData:[NSData data]];
    
    Challenge *newChallenge = [Challenge challengeForParseObject:parseObject];
    XCTAssertEqual(newChallenge.whosTurn, noonesTurn);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
