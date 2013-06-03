#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface KVDB : NSObject {
    NSString *_file;
}
@property (nonatomic, retain) NSString *file;

+ (id)sharedDB;
+ (id)sharedDBUsingFile:(NSString *)file;

- (id)initWithSQLFile:(NSString *)sqliteFile;

- (void)createDatabase;
- (void)dropDatabase;

- (void)setValue:(id)object forKey:(NSString *)key;
- (void)removeValueForKey:(NSString *)key;
- (id)valueForKey:(NSString *)key;

/* Compatibilty with other frameworks */
- (void)setObject:(id)object forKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key;
- (id)objectForKey:(NSString *)key;

- (NSArray *)allObjects;
- (NSUInteger)count;

@end

int kvdbQueryCallback(void *resultBlock, int argc, char **argv, char **column);
