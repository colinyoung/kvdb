//
//  DatabaseTestCase.m
//  kvdb
//
//  Created by Colin Young on 2/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "kvdb.h"
#import "KVDB_Private.h"

@interface kvdbTests : XCTestCase
@end

@implementation kvdbTests

- (void)setUp {
    [[KVDB sharedDB] dropDatabase];
    [KVDB resetDB];
}

- (void)testSerialization {
    NSString *testString = @"Test string is awesome.";
    NSString *testKey = @"test_str_key";
    [[KVDB sharedDB] setValue:testString forKey:testKey];
    
    id obj = [[KVDB sharedDB] valueForKey:testKey];
    XCTAssertEqualObjects(obj, testString, @"Serialized and deserialized objects are equal.");
    
    [[KVDB sharedDB] removeValueForKey:testKey];
    
    obj = [[KVDB sharedDB] valueForKey:testKey];
    
    XCTAssertNil(obj, @"Key is removed.");
}

- (void)testSettingNilValueForAGivenKeyUsingSetObjectForKey {
    NSString *testKey = @"test_str_key";

    XCTAssertThrowsSpecificNamed(^{
        [[KVDB sharedDB] setObject:nil forKey:testKey];
    }(), NSException, NSInvalidArgumentException);
}

- (void)testSettingNilValueForAGivenKeyUsingSetValueForKey {
    NSString *testKey = @"test_str_key";
    NSString *testString = @"Test string is awesome.";

    [[KVDB sharedDB] setValue:testString forKey:testKey];

    id dbValue = [[KVDB sharedDB] valueForKey:testKey];
    XCTAssertTrue([dbValue isEqual:testString]);

    [[KVDB sharedDB] setValue:nil forKey:testKey];
    dbValue = [[KVDB sharedDB] valueForKey:testKey];

    XCTAssertNil(dbValue);
}

- (void)testSettingAndGettingNSNullValueForAGivenKey {
    NSString *testKey = @"test_str_key";

    id nullValue = [NSNull null];

    [[KVDB sharedDB] setValue:nullValue forKey:testKey];

    id dbNullValue = [[KVDB sharedDB] valueForKey:testKey];

    XCTAssertTrue([nullValue isEqual:dbNullValue]);
}

- (void)testKVDBDataLivesBeetweenInstances {
    NSString *testString = @"Test string is awesome.";
    NSString *testKey = @"test_str_key";

    [[KVDB sharedDB] setValue:testString forKey:testKey];

    id obj = [[KVDB sharedDB] valueForKey:testKey];
    XCTAssertEqualObjects(obj, testString, @"Serialized and deserialized objects are equal.");

    [KVDB resetDB];

    obj = [[KVDB sharedDB] valueForKey:testKey];
    XCTAssertEqualObjects(obj, testString, @"Serialized and deserialized objects are equal.");
}


- (void)testCount {
    KVDB *DB = [KVDB sharedDB];
    XCTAssertEqual((int)DB.count, 0);

    int N = 10;

    for (int i = 1; i < N; i++) {
        NSString *testString = @"Test string is awesome.";
        NSString *testKey = [NSString stringWithFormat:@"test_str_key#%d", i];
        [DB setValue:testString forKey:testKey];

        XCTAssertEqual((int)DB.count, i);
    }

    for (int i = N; i > 0; i--) {
        NSString *testKey = [NSString stringWithFormat:@"test_str_key#%d", i];

        [DB removeValueForKey:testKey];

        XCTAssertEqual((int)DB.count, (i - 1));
    }

    XCTAssertEqual((int)DB.count, 0);
}

@end
