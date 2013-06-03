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
