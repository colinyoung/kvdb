//
//  FilesTestCase.m
//  kvdb
//
//  Created by Colin Young on 2/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import "kvdb.h"
#import "KVDB_Private.h"
#import "KVDBFunctions.h"

@interface FilesTestCase : SenTestCase
@end

@implementation FilesTestCase

- (void)setUp {
    [[KVDB sharedDB] dropDatabase];
    [KVDB resetDB];
}

- (void)testFileName {
    STAssertEqualObjects([[KVDB sharedDB] file], [KVDocumentsDirectory() stringByAppendingPathComponent:@"kvdb.sqlite3"], @"Test default filename is correct.");
}

- (void)testFileCanBeCreated {
    NSFileManager *fm = [NSFileManager defaultManager];
    STAssertTrue([fm fileExistsAtPath:[[KVDB sharedDB] file]], @"File created and exists");
}

- (void)testSharedDBUsingFileInDirectory {
    NSString *file = @"kvdb.sqlite3";
    NSString *directory = KVDocumentsDirectory();
    
    STAssertEqualObjects([[KVDB sharedDBUsingFile:file inDirectory:directory] file], [directory stringByAppendingPathComponent:file], nil);
}

@end
