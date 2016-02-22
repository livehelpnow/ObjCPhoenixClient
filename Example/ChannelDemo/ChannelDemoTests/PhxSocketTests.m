//
//  PhxSocketTests.m
//  ChannelDemo
//
//  Created by Jose Alcalá-Correa on 22/02/16.
//  Copyright © 2016 PhoenixFramework. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <PhoenixClient/PhoenixClient.h>

@interface PhxSocketTests : XCTestCase

@end

@implementation PhxSocketTests

- (void)testIncreasingReference {
    PhxSocket *socket = [[PhxSocket alloc] initWithURL:[NSURL URLWithString:@"http://test.com/socket"]];

    NSString *ref = [socket makeRef];
    XCTAssertEqualObjects(ref, @"1");

    ref = [socket makeRef];
    XCTAssertEqualObjects(ref, @"2");

    ref = [socket makeRef];
    XCTAssertEqualObjects(ref, @"3");
}

@end
