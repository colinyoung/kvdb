//
//  FilesTestCase.m
//  kvdb
//
//  Created by Colin Young on 2/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FilesTestCase.h"

#import "KVDB.h"
#import "KVDBFunctions.h"

#import <UIKit/UIKit.h>
//#import "application_headers" as required

@implementation FilesTestCase

// All code under test is in the iOS Application
- (void)testAppDelegate
{
    id yourApplicationDelegate = [[UIApplication sharedApplication] delegate];
    NSLog(@"Writing to application directory: %@", KVDocumentsDirectory());
    STAssertNotNil(yourApplicationDelegate, @"UIApplication failed to find the AppDelegate");
}

- (void)testFileName {
    STAssertEqualObjects([[KVDB sharedDB] file], [KVDocumentsDirectory() stringByAppendingPathComponent:@"kvdb.sqlite3"],
                   @"Test default filename is correct.");
}

- (void)testFileCanBeCreated {
    NSFileManager *fm = [NSFileManager defaultManager];
    STAssertTrue([fm fileExistsAtPath:[[KVDB sharedDB] file]], @"File created and exists");
}

@end
