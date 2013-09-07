#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface KVDB : NSObject

+ (instancetype)sharedDB;
+ (instancetype)sharedDBUsingFile:(NSString *)file;
+ (instancetype)sharedDBUsingFile:(NSString *)file inDirectory:(NSString *)directory;

- (instancetype)initWithSQLFile:(NSString *)sqliteFile;
- (instancetype)initWithSQLFile:(NSString *)sqliteFile inDirectory:(NSString *)directory;

- (void)createDatabase;
- (void)dropDatabase;

- (void)performBlock:(void(^)(id DB))block;
- (void)performBlockAndWait:(void(^)(id DB))block;

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
