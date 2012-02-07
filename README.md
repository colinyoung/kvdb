kvdb
====

**kvdb** is a key-value store for iOS backed by Sqlite3.

It can serialize and store any objects that implement the `NSCoding` protocol.

Therefore, lots of objects are supported right away:

- `NSDictionary`
- `NSArray`
- `NSNumber`
- `NSString`

etc.

usage
----

	```objective-c
    #import "KVDB.h"

    [[KVDB sharedDB] setValue:@"apple" forKey:@"fruit"];
	[[KVDB sharedDB] setValue:@"Chicago" forKey:@"city"];
	
	MyObject *object = [[MyObject alloc] initWithTitle:@"KVDB"]
	[[KVDB sharedDB] setValue:object forKey:@"my_object"];
	```

installation
-----

	```objective-c
    > git submodule add https://github.com/colinyoung/kvdb.git dependencies/kvdb
    > git submodule update --init
	```

other stuff
-----
    ```objective-c
    [[KVDB sharedDB] dropDatabase]

	[[KVDB sharedDB] createDatabase]

    // Instantiate w/ a different file:
    [KVDB sharedDBWithFile:@"blah.sqlite3"] // the file will be created in your documents directory.
    ```