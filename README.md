# kvdb

**kvdb** is a key-value store for iOS backed by SQLite3.

It can serialize and store any objects that implement the `NSCoding` protocol.

Therefore, lots of objects are supported right away:

- `NSDictionary`
- `NSArray`
- `NSNumber`
- `NSString`

etc.

## Usage

```objective-c
#import "KVDB.h"

[[KVDB sharedDB] setValue:@"apple" forKey:@"fruit"];
[[KVDB sharedDB] setValue:@"Chicago" forKey:@"city"];

MyObject *object = [[MyObject alloc] initWithTitle:@"KVDB"]
[[KVDB sharedDB] setValue:object forKey:@"my_object"];
```

## Installation

The recommended way is to install via Cocoapods:

Add into your Podfile:

```ruby
pod 'kvdb', :git => 'https://github.com/colinyoung/kvdb'
```

And run 

```
pod update
```

or you can just clone `kvdb` and add `kvdb/` folder to your project.

## Other stuff

```objective-c
[[KVDB sharedDB] dropDatabase]

[[KVDB sharedDB] createDatabase]

// Instantiate w/ a different file:
[KVDB sharedDBWithFile:@"blah.sqlite3"] // the file will be created in your documents directory.
```

## Notes

* `kvdb` is a simple `key value store for iOS` solution with codebase containing just a couple of files. Don't ask it what it is not intended for. For more serious solutions see "Similar tools".
* `kvdb` plays very nice with all the solutions like [Mantle](https://github.com/github/Mantle), which provide auto-coding for all the properties you declare in your classes. For example, if using `Mantle`: create a `MTLModel` subclass, declare its properties, and... it is ready to be stored in a KVDB store, because `Mantle` has already autocoded these properties for you.

## Similar tools

* [NanoStore](https://github.com/tciuro/NanoStore/)
* [YapDatabase](https://github.com/yaptv/YapDatabase)

## Copyright

Copyright (c) 2012 Colin Young. See LICENSE for details.
