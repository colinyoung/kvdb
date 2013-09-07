//
//  kvdbTests.m
//  kvdbTests
//
//  Created by Colin Young on 2/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import "KVDB.h"
#import "KVDBFunctions.h"

@interface kvdbTests : SenTestCase
@end

@implementation kvdbTests

- (void)setUp
{
    [super setUp];
    
    [[KVDB sharedDB] dropDatabase];
    [[KVDB sharedDB] createDatabase];
}

- (void)tearDown
{
    [super tearDown];
    
    [[KVDB sharedDB] dropDatabase];
}

- (void)testCount {
    KVDB *DB = [KVDB sharedDB];
    STAssertEquals((int)DB.count, 0, nil);

    NSString *testString = @"Test string is awesome.";
    NSString *testKey = @"test_str_key";
    [DB setValue:testString forKey:testKey];

    STAssertEquals((int)DB.count, 1, nil);
    
    [DB removeValueForKey:testKey];

    STAssertEquals((int)DB.count, 0, nil);
}

@end
