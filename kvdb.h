#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface KVDB : NSObject {
    NSString *_file;
    sqlite3 *DB;
}
@property (nonatomic, retain) NSString *file;

+(id)sharedDB;
+ (KVDB*)sharedDBUsingFile:(NSString *)file;
-(id)initWithSQLFile:(NSString *)sqliteFile;

-(void)createDatabase;
-(void)dropDatabase;

-(void)setValue:(id)object forKey:(NSString *)key;
-(id)valueForKey:(NSString *)key;

-(NSArray *)allObjects;
-(NSUInteger)count;

@end

int kvdbQueryCallback(void *resultBlock, int argc, char **argv, char **column);
int Callback(void *pArg, int argc, char **argv, char **columnNames);