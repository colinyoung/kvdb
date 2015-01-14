//
//  FilesTestCase.m
//  kvdb
//
//  Created by Colin Young on 2/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "kvdb.h"
#import "KVDB_Private.h"
#import "KVDBFunctions.h"

@interface FilesTestCase : XCTestCase
@end

@implementation FilesTestCase

- (void)setUp {
    [[KVDB sharedDB] dropDatabase];
    [KVDB resetDB];
}

- (void)testFileName {
    XCTAssertEqualObjects([[KVDB sharedDB] file], [KVDocumentsDirectory() stringByAppendingPathComponent:@"kvdb.sqlite3"], @"Test default filename is correct.");
}

- (void)testFileCanBeCreated {
    NSFileManager *fm = [NSFileManager defaultManager];
    XCTAssertTrue([fm fileExistsAtPath:[[KVDB sharedDB] file]], @"File created and exists");
}

- (void)testSharedDBUsingFileInDirectory {
    NSString *file = @"kvdb.sqlite3";
    NSString *directory = KVDocumentsDirectory();
    
    XCTAssertEqualObjects([[KVDB sharedDBUsingFile:file inDirectory:directory] file], [directory stringByAppendingPathComponent:file]);
}

@end
