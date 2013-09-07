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

## Coding nil-values: nil vs NSNull

To provide a compatibility with `NSArray` and `NSDictionary` classes `KVDB` denies the coding of `nil` values. Like it is done when working with instances of NSArray or NSDictionary use `NSNull` class whereever you want to use `-[KVDB setValue:forKey]` provide a given key with a null value.

So use

```objective-c
[[KVDB sharedDB] setValue:[NSNull null] forKey:@"fruit"];

id dbValue = [[KVDB sharedDB] valueForKey:testKey]; 

NSLog(@"%@", dbValue); // will print "<null>" i.e.  NSNull singleton
```

Instead of

```objective-c
[[KVDB sharedDB] setValue:nil forKey:@"fruit"]; // => Results in NSInternalInconsistencyException
```

See [the documentation of -[NSDictionary setObject:forKey:]](https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/Classes/NSMutableDictionary_Class/Reference/Reference.html#//apple_ref/occ/instm/NSMutableDictionary/setObject:forKey:)
and this nice [NSHipster article about nil and NSNull](http://nshipster.com/nil/).

## Notes

* `kvdb` is a simple `key value store for iOS` solution with codebase containing just a couple of files. Don't ask it what it is not intended for. For more serious solutions see "Similar tools".
* `kvdb` plays very nice with all the solutions like [Mantle](https://github.com/github/Mantle), which provide auto-coding for all the properties you declare in your classes. For example, if using `Mantle`: create a `MTLModel` subclass, declare its properties, and... it is ready to be stored in a KVDB store, because `Mantle` has already autocoded these properties for you.

## Similar tools

* [NanoStore](https://github.com/tciuro/NanoStore/)
* [YapDatabase](https://github.com/yaptv/YapDatabase)

## Copyright

Copyright (c) 2012 Colin Young. See LICENSE for details.
