//
//  DatabaseTestCase.m
//  kvdb
//
//  Created by Colin Young on 2/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import <UIKit/UIKit.h>
#import "KVDB.h"
#import "KVDB_Private.h"

@interface DatabaseTestCase : SenTestCase
@end

@implementation DatabaseTestCase

// All code under test is in the iOS Application

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
    
    [[KVDB sharedDB] removeValueForKey:testKey];
    
    obj = [[KVDB sharedDB] valueForKey:testKey];
    
    STAssertNil(obj, @"Key is removed.");
}

- (void)testSettingAndGettingNilValueForAGivenKey {
    NSString *testKey = @"test_str_key";

    STAssertThrowsSpecificNamed(^{
        [[KVDB sharedDB] setValue:nil forKey:testKey];
    }(), NSException, NSInternalInconsistencyException, nil);
}

- (void)testSettingAndGettingNSNullValueForAGivenKey {
    NSString *testKey = @"test_str_key";

    id nullValue = [NSNull null];

    [[KVDB sharedDB] setValue:nullValue forKey:testKey];

    id dbNullValue = [[KVDB sharedDB] valueForKey:testKey];

    STAssertTrue([nullValue isEqual:dbNullValue], nil);
}

- (void)testKVDBDataLivesBeetweenInstances {
    NSString *testString = @"Test string is awesome.";
    NSString *testKey = @"test_str_key";

    [[KVDB sharedDB] setValue:testString forKey:testKey];

    id obj = [[KVDB sharedDB] valueForKey:testKey];
    STAssertEqualObjects(obj, testString, @"Serialized and deserialized objects are equal.");

    [KVDB resetDB];

    obj = [[KVDB sharedDB] valueForKey:testKey];
    STAssertEqualObjects(obj, testString, @"Serialized and deserialized objects are equal.");
}

@end
