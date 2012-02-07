//
//  kvdbTests.m
//  kvdbTests
//
//  Created by Colin Young on 2/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "KVDB.h"
#import "KVDBFunctions.h"

#import "kvdbTests.h"

@implementation kvdbTests

- (void)setUp
{
    [super setUp];
    [[KVDB sharedDB] dropDatabase];
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
    [[KVDB sharedDB] dropDatabase];
}

@end
