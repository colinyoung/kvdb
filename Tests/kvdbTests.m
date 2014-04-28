//
//  kvdbTests.m
//  kvdbTests
//
//  Created by Colin Young on 2/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import "kvdb.h"
#import "KVDBFunctions.h"

@interface kvdbTests : SenTestCase
@end

@implementation kvdbTests

- (void)setUp {
    [[KVDB sharedDB] dropDatabase];
    [KVDB resetDB];
}

- (void)testCount {
    KVDB *DB = [KVDB sharedDB];
    STAssertEquals((int)DB.count, 0, nil);

    int N = 10;

    for (int i = 1; i < N; i++) {
        NSString *testString = @"Test string is awesome.";
        NSString *testKey = [NSString stringWithFormat:@"test_str_key#%d", i];
        [DB setValue:testString forKey:testKey];

        STAssertEquals((int)DB.count, i, nil);
    }

    for (int i = N; i > 0; i--) {
        NSString *testKey = [NSString stringWithFormat:@"test_str_key#%d", i];

        [DB removeValueForKey:testKey];

        STAssertEquals((int)DB.count, (i - 1), nil);
    }

    STAssertEquals((int)DB.count, 0, nil);
}

@end
