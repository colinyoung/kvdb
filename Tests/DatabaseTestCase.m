//
//  DatabaseTestCase.m
//  kvdb
//
//  Created by Colin Young on 2/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import <UIKit/UIKit.h>
#import "kvdb.h"
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

- (void)testSettingNilValueForAGivenKeyUsingSetObjectForKey {
    NSString *testKey = @"test_str_key";

    STAssertThrowsSpecificNamed(^{
        [[KVDB sharedDB] setObject:nil forKey:testKey];
    }(), NSException, NSInvalidArgumentException, nil);
}

- (void)testSettingNilValueForAGivenKeyUsingSetValueForKey {
    NSString *testKey = @"test_str_key";
    NSString *testString = @"Test string is awesome.";

    [[KVDB sharedDB] setValue:testString forKey:testKey];

    id dbValue = [[KVDB sharedDB] valueForKey:testKey];
    STAssertTrue([dbValue isEqual:testString], nil);

    [[KVDB sharedDB] setValue:nil forKey:testKey];
    dbValue = [[KVDB sharedDB] valueForKey:testKey];

    STAssertNil(dbValue, nil);
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
