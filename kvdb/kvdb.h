#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface KVDB : NSObject {
    NSString *_file;
}

@property (nonatomic, retain) NSString *file;

+ (id)sharedDB;
+ (id)sharedDBUsingFile:(NSString *)file;
+ (id)sharedDBUsingFile:(NSString *)file inDirectory:(NSString *)directory;

- (id)initWithSQLFile:(NSString *)sqliteFile;
- (id)initWithSQLFile:(NSString *)sqliteFile inDirectory:(NSString *)directory;

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

int kvdbQueryCallback(void *resultBlock, int argc, char **argv, char **column);
