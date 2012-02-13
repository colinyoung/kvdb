#import "KVDB.h"
#import "KVDB/KVDBFunctions.h"

typedef void(^KVBlock)(void);
typedef void(^KVDictBlock)(NSDictionary *dict);

#define kKVDBTableName @"kvdb"

@interface KVDB (Private)

-(void)createDBFile;
-(sqlite3*)openDatabase;
-(void)closeDatabase:(sqlite3*)db;
-(NSArray*)queryDatabase:(sqlite3 *)db statement:(NSString *)statement;
-(void)queryDatabase:(sqlite3 *)db statement:(NSString *)statement result:(void (^)(NSDictionary *))resultBlock;
-(void)queryDatabase:(sqlite3 *)db statement:(NSString *)statement data:(NSData*)data result:(void (^)(BOOL success, NSDictionary * result))resultBlock;
-(NSArray *)tablesInDatabase:(sqlite3 *)db;

-(NSString *)_upsertQueryWithKey:(NSString *)key;
-(NSString *)_selectQueryForKey:(NSString *)key;
-(NSString *)_deleteQueryForKey:(NSString *)key;
-(void)_writeObject:(id)objC inDatabase:(sqlite3*)DB toBlob:(sqlite3_blob**)blob;
-(NSData*)_readBlobFromDatabaseNamed:(NSString *)dbName tableName:(NSString *)tableName columnName:(NSString *)columnName rowID:(NSUInteger)rowID blob:(sqlite3_blob**)blob;

-(NSData*)archiveObject:(id)object;
-(id)unarchiveData:(NSData*)data;

@end

@implementation KVDB

@synthesize file = _file;

#define kDefaultSQLFile @"kvdb.sqlite3"

static KVDB *kvdbInstance = NULL;

+ (KVDB*)sharedDB
{
    @synchronized(self)
    {
        if (kvdbInstance == NULL)
            kvdbInstance = [[self alloc] initWithSQLFile:kDefaultSQLFile];
    }
    
    return kvdbInstance;
}

+ (KVDB*)sharedDBUsingFile:(NSString *)file
{
    @synchronized(self)
    {
        if (kvdbInstance == NULL)
            kvdbInstance = [[self alloc] initWithSQLFile:file];
    }
    
    return kvdbInstance;
}

-(id)initWithSQLFile:(NSString *)sqliteFile {
    self = [super init];
    if (self) {
        self.file = [KVDocumentsDirectory() stringByAppendingPathComponent:sqliteFile];
        NSLog(@"Initializing Shared DB with file: %@", self.file);
        [self createDBFile];
    }
    return self;
}
         
-(void)dealloc {
    _file = nil; [_file release];    
    [super dealloc];
}

#pragma mark - DB Setup
-(void)createDatabase {
    
    sqlite3* db = [self openDatabase];
    [self queryDatabase:db statement:[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (key TEXT PRIMARY KEY, value BLOB)", kKVDBTableName]];
    
    // Verify
    [self tablesInDatabase:db];
    
    [self closeDatabase:db];
}

-(void)dropDatabase {
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:self.file error:&error];
    if (error) @throw KVDBExceptionWrite();
}

#pragma mark - DB functions
-(void)setValue:(id)object forKey:(NSString *)key {
    sqlite3* DB = [self openDatabase];
    
    [self queryDatabase:DB
              statement:[self _upsertQueryWithKey:key]
                   data:[self archiveObject:object]
                 result:^(BOOL success, NSDictionary *result) {
        // Null implementation, this could get slow.
    }];
    
    [self closeDatabase:DB];
}

-(id)valueForKey:(NSString *)key {
    NSDictionary* value = nil;
    
    sqlite3* DB = [self openDatabase];
    
    NSArray *values = [self queryDatabase:DB statement:[self _selectQueryForKey:key]];
    if (values) value = [values objectAtIndex:0];
    if (value) value = [value objectForKey:@"value"];
    
    [self closeDatabase:DB];
    
    return value;
}

-(void)removeValueForKey:(NSString *)key {
    sqlite3* DB = [self openDatabase];
    
    [self queryDatabase:DB statement:[self _deleteQueryForKey:key]];
    
    [self closeDatabase:DB];
}

#pragma mark Compatibilty
-(void)setObject:(id)object forKey:(NSString *)key {
    [self setValue:object forKey:key];
}
-(void)removeObjectForKey:(NSString *)key {
    [self removeValueForKey:key];
}
-(id)objectForKey:(NSString *)key {
    return [self valueForKey:key];
}

-(NSArray *)allObjects {
    id value = nil;
    
    sqlite3* DB = [self openDatabase];
    
    value = [self queryDatabase:DB statement:[NSString stringWithFormat:@"SELECT key, value FROM %@", kKVDBTableName]];
    
    [self closeDatabase:DB];
    
    return value;    
}

-(NSUInteger)count {
    
    sqlite3* DB = [self openDatabase];
    NSArray *records = nil;
    NSInteger ct = 0;
    records = [self queryDatabase:DB statement:[NSString stringWithFormat:@"Select count(*) as value from %@", kKVDBTableName]];
    if (records != nil) {
        ct = [[[records objectAtIndex:0] objectForKey:@"value"] intValue];
    }
    [self closeDatabase:DB];    
    return ct;
}

@end

#pragma mark - Private methods
@implementation KVDB (Private)

-(void)createDBFile {
    NSFileManager *fm = [NSFileManager defaultManager];
//    NSError *error = nil;
    
    if ([fm fileExistsAtPath:self.file]) {
//        [fm removeItemAtPath:self.file error:&error];
//        if (error) @throw KVDBExceptionWrite();
    }
    
    [self createDatabase];
}

#pragma mark - SQLITE methods
-(sqlite3*)openDatabase {
    sqlite3* db = NULL;
    
    const char *dbpath = [self.file UTF8String];
    if (sqlite3_open(dbpath, &db) != SQLITE_OK) {
        @throw KVDBExceptionDBOpen();
    }
    
    return db;
}

-(void)closeDatabase:(sqlite3 *)db {
    sqlite3_close(db);
}

/* Returns an array of rows */
-(NSArray*)queryDatabase:(sqlite3 *)db statement:(NSString *)statement {
    const char *sql = [statement UTF8String];
    const char *tail;
    sqlite3_stmt *stmt;
    
    if ((sqlite3_prepare_v2(db, sql, -1, &stmt, &tail) != SQLITE_OK)) {
        return nil; /* No data found. */
    }
    
    NSMutableArray *array = nil;
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        if (array == nil) array = [NSMutableArray array];
        
        const char *keyText = (const char *)sqlite3_column_text(stmt, 0);
        if (keyText == nil) continue;
        
        NSString *key = [NSString stringWithCString:keyText encoding:NSUTF8StringEncoding];
        NSData *blob = [NSData dataWithBytes:sqlite3_column_blob(stmt, 1) length:sqlite3_column_bytes(stmt, 1)];
        NSMutableDictionary *rowDict = [NSMutableDictionary dictionaryWithObject:key forKey:@"key"];
                          
        if ([blob length]) {
            id value = [self unarchiveData:blob];
            [rowDict setObject:value forKey:@"value"];
        }
        
        [array addObject:rowDict];
    }
    
    sqlite3_finalize(stmt);
    
    return array;
}

/* Doesn't use blobs, so simply queries. */
-(void)queryDatabase:(sqlite3 *)db statement:(NSString *)statement result:(void (^)(NSDictionary *))resultBlock {
    
    char *errMsg;
    int result = sqlite3_exec(db, [statement UTF8String], kvdbQueryCallback, resultBlock, &errMsg);
    if (result != SQLITE_OK) {
        NSString *errorMsg = [[[NSString alloc] initWithUTF8String:errMsg] autorelease];
        sqlite3_free(errMsg);        
        resultBlock([NSDictionary dictionaryWithObject:errorMsg forKey:@"error"]);    
        return;
    }
}

/* Writes blobs, so it uses transactions */
-(void)queryDatabase:(sqlite3 *)db statement:(NSString *)statement data:(NSData*)data result:(void (^)(BOOL success, NSDictionary *))resultBlock {
    
    // @todo this is totally inflexible to argument count
    const char *sql = [statement UTF8String];
    sqlite3_stmt *stmt;
        
    if ((sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) == SQLITE_OK)) {
        sqlite3_bind_blob(stmt, 1, [data bytes], [data length], SQLITE_STATIC);
    }
    
    int status = sqlite3_step(stmt);
    if (status != SQLITE_DONE) {
        const char* errMsg = sqlite3_errmsg(db);
        NSString *errorMsg = [[[NSString alloc] initWithUTF8String:errMsg] autorelease];
        resultBlock(NO, [NSDictionary dictionaryWithObject:errorMsg forKey:@"error"]);
    }
    
    sqlite3_finalize(stmt);
    
    resultBlock(YES, [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithInt:sqlite3_last_insert_rowid(db)], @"lastRowID",
                        [NSNumber numberWithInt:sqlite3_changes(db)], @"rowsChanged"
                      , nil]);
}

-(NSArray *)tablesInDatabase:(sqlite3 *)db {
    [self queryDatabase:db 
              statement:@"SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;"
                 result:^(NSDictionary *result) {
                     if (![[result objectForKey:@"name"] isEqualToString:kKVDBTableName])
                         @throw [NSException exceptionWithName:@"SQLITEError"
                                                        reason:[NSString stringWithFormat:@"There should have been a table called %@.", kKVDBTableName]
                                                      userInfo:nil];
    }];
    
    return nil;
}

#pragma mark - Data/query methods

/* Upsert via SO contributor Eric B; 
    Updates or inserts safely.
 http://stackoverflow.com/questions/418898/sqlite-upsert-not-insert-or-replace/4253806#4253806
 */
-(NSString *)_upsertQueryWithKey:(NSString *)key {
    return [NSString stringWithFormat:@"INSERT OR REPLACE INTO `%@` (`key`,`value`)" // table
            "VALUES ( '%@', ?); COMMIT;",
            kKVDBTableName, key];
}

-(NSString *)_selectQueryForKey:(NSString *)key {
    return [NSString stringWithFormat:@"SELECT key, value FROM %@ WHERE key='%@'", kKVDBTableName, key];
}

-(NSString *)_deleteQueryForKey:(NSString *)key {
    return [NSString stringWithFormat:@"DELETE FROM %@ WHERE key='%@'", kKVDBTableName, key];
}


/* Call this function with a sqlite3_blob* initialized to NULL. */
-(void)_writeObject:(id)objC inDatabase:(sqlite3*)DB toBlob:(sqlite3_blob**)blob {

    if (*blob != NULL) {
        @throw [NSException exceptionWithName:@"SQLITEError" reason:@"Can only write to NULL blobs." userInfo:nil];
    }
    
    // Opening the blob with no data
    sqlite3_blob_open(DB, NULL, NULL, NULL, 0, 1 /* Open for writing */, blob);
    
    // Objects must conform to NSCoding since we are using NSKeyedArchiver for data serialization.
    if (![objC conformsToProtocol:@protocol(NSCoding)]) {
        @throw KVDBExceptionNoCoding(objC);
    }
    
    NSData *data = [self archiveObject:objC];
    int byteCt = [data length];
    Byte *byteData = (Byte*)malloc(byteCt);
    memcpy(byteData, [data bytes], byteCt);
    sqlite3_blob_write(*blob, byteData, byteCt, 0);
    free(byteData);
}

/* Call this function with a sqlite3_blob* initialized to NULL. */
-(NSData*)_readBlobFromDatabaseNamed:(NSString *)dbName tableName:(NSString *)tableName columnName:(NSString *)columnName rowID:(NSUInteger)rowID blob:(sqlite3_blob**)blob
{
    if (*blob != NULL) {
        @throw [NSException exceptionWithName:@"SQLITEError" reason:@"Can only read to NULL blobs." userInfo:nil];
    }
    
    int status = sqlite3_blob_open([self openDatabase], [dbName UTF8String], [tableName UTF8String], [columnName UTF8String], rowID, 0 /* Open for reading */, blob);
    if (status != SQLITE_OK) {
        @throw KVDBExceptionDBRead();
    }
    
    int byteCt = sqlite3_blob_bytes(*blob);
    Byte byteBuff[byteCt];
    
    return [NSData dataWithBytes:byteBuff length:byteCt];
}

-(NSData *)archiveObject:(id)object {
    return [NSKeyedArchiver archivedDataWithRootObject:object];
}

-(id)unarchiveData:(NSData *)data {
    if (data == nil) return nil;
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

@end

#pragma mark - Sqlite3 callback
int kvdbQueryCallback(void *resultBlock, int argc, char **argv, char **column) {
    
    // converts row to an nsdictionary
    NSMutableDictionary *row = [NSMutableDictionary dictionary];
    for (int i=0; i< argc; i++) {
        NSString *columnName = [NSString stringWithCString:column[i] encoding:NSUTF8StringEncoding];
        id value = nil;
        if (![columnName isEqualToString:@"value"]) {
            value = [NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding];
        } else {
            sqlite3_int64 rowID = 0;
            sqlite3_blob *blob = NULL;
            NSData *data = [[KVDB sharedDB] _readBlobFromDatabaseNamed:@"main"
                             tableName:kKVDBTableName
                            columnName:@"value"
                                 rowID:rowID
                                  blob:&blob];
            // Revive object from NSKeyedArchiver
            if (data != nil)
                value = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        }
        
        if (value != nil) [row setObject:value forKey:columnName];
    }
    
    KVDictBlock objcBlk = resultBlock;
    objcBlk(row);
    
    return 0;
}
