#import <Foundation/Foundation.h>
#import <sqlite3.h>

__attribute__((__visibility__("default")))
@interface KVDB : NSObject

+ (instancetype)sharedDB;
+ (instancetype)sharedDBUsingFile:(NSString *)file;
+ (instancetype)sharedDBUsingFile:(NSString *)file inDirectory:(NSString *)directory;
+ (void)resetDB;

- (instancetype)initWithSQLFile:(NSString *)sqliteFile;
- (instancetype)initWithSQLFile:(NSString *)sqliteFile inDirectory:(NSString *)directory;

- (void)createDatabase;
- (void)dropDatabase;

@end

@interface KVDB (NSKeyValueCoding)

- (void)setValue:(id)value forKey:(NSString *)key;
- (void)removeValueForKey:(NSString *)key;
- (id)valueForKey:(NSString *)key;

- (void)setObject:(id)object forKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key;
- (id)objectForKey:(NSString *)key;

- (NSArray *)allObjects;
- (NSUInteger)count;

@end
