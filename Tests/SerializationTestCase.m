//
//  SerializationTestCase.m
//  kvdb
//
//  Created by Colin Young on 2/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import <UIKit/UIKit.h>
#import "kvdb.h"

@interface SerializationTestCase : SenTestCase
@end

@implementation SerializationTestCase

- (void)setUp {
    [[KVDB sharedDB] dropDatabase];
    [KVDB resetDB];
}

- (void)testSerialization {
    NSString *testString = @"Test string is awesome.";
    NSString *testKey = @"test_str_key";
    [[KVDB sharedDB] setValue:testString forKey:testKey];
    
    id obj = [[KVDB sharedDB] valueForKey:testKey];
    STAssertEqualObjects(obj, testString, @"Serialized and deserialized objects are equal.");
}

@end
