#import "kvdb.h"
#import "KVDB_Private.h"

#import "KVDBFunctions.h"

#if !__has_feature(objc_arc)
#error KVDB must be built with ARC.
#endif

typedef void(^KVBlock)(void);
typedef void(^KVDictBlock)(NSDictionary *dict);

static int kvdbQueryCallback(void *resultBlock, int argc, char **argv, char **column);

#define kKVDBTableName @"kvdb"

@implementation KVDB

#define kDefaultSQLFile @"kvdb.sqlite3"

static KVDB *kvdbInstance = nil;

- (id)init {
    NSString *reason = [NSString stringWithFormat:@"-[%@ init] must not be called directly. Use designated initializers instead: -[%@ initWithSQLFile:] or -[%@ initWithSQLFile:inDirectory:].", [self class], [self class], [self class]];
    @throw [NSException exceptionWithName:NSGenericException reason:reason userInfo:nil];
}

- (void)dealloc {
    self.file = nil;
}

#pragma mark - Public API: Initialization

- (instancetype)initWithSQLFile:(NSString *)sqliteFile {
    self = [self initWithSQLFile:sqliteFile inDirectory:KVDocumentsDirectory()];

    if (self == nil) return nil;

    return self;
}

- (instancetype)initWithSQLFile:(NSString *)sqliteFile inDirectory:(NSString *)directory {
    self = [super init];

    if (self == nil) return nil;

    self.file = [directory stringByAppendingPathComponent:sqliteFile];
    [self createDatabase];

    return self;
}

+ (instancetype)sharedDB {
    if (kvdbInstance == nil) {
        @synchronized(self) {
            if (kvdbInstance == nil) {
                kvdbInstance = [[self alloc] initWithSQLFile:kDefaultSQLFile];
            }
        }
    }

    return kvdbInstance;
}

+ (instancetype)sharedDBUsingFile:(NSString *)file {
    if (kvdbInstance == nil) {
        @synchronized(self) {
            if (kvdbInstance == nil) {
                kvdbInstance = [[self alloc] initWithSQLFile:file];
            }
        }
    }

    return kvdbInstance;
}

+ (instancetype)sharedDBUsingFile:(NSString *)file inDirectory:(NSString *)directory {
    if (kvdbInstance == nil) {
        @synchronized(self) {
            if (kvdbInstance == nil) {
                kvdbInstance = [[self alloc] initWithSQLFile:file inDirectory:directory];
            }
        }
    }

    return kvdbInstance;
}

+ (void)resetDB {
    kvdbInstance = nil;
}

#pragma mark - Public API: Creating and dropping database

- (void)createDatabase {
    sqlite3 *db = [self _openDatabase];

    [self _createKVDBTableIfNotExistsInDB:db];
    [self _ensureKVDBTableExistsInDB:db];

    [self _closeDatabase:db];
}

- (void)dropDatabase {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;

    if ([fileManager fileExistsAtPath:self.file]) {
        [fileManager removeItemAtPath:self.file error:&error];
        if (error) @throw KVDBExceptionWrite();
    }
}

#pragma mark - Public API: NSKeyValueCoding

- (void)setValue:(id)value forKey:(NSString *)key {
    if (value == nil) {
        [self removeValueForKey:key];
        return;
    }

    [self _performAccessToDatabaseWithBlock:^(sqlite3 *database) {
        [self _queryDatabase:database
                   statement:[self _upsertKeyQuery]
                         key:key
                        data:[self archiveObject:value]
                      result:^(BOOL success, NSDictionary *result) {
                          // Null implementation, this could get slow.
                      }];
    }];
}

- (id)valueForKey:(NSString *)key {
    __block NSDictionary *value;

    [self _performAccessToDatabaseWithBlock:^(sqlite3 *database) {
        NSArray *values = [self _queryDatabase:database statement:[self _selectKeyQuery] key:key];

        if (values) value = [values objectAtIndex:0];
        if (value) value = [value objectForKey:@"value"];
    }];

    return value;
}

- (void)removeValueForKey:(NSString *)key {
    [self _performAccessToDatabaseWithBlock:^(sqlite3 *database) {
        [self _queryDatabase:database statement:[self _deleteKeyQuery] key:key];
    }];
}

- (void)setObject:(id)object forKey:(NSString *)key {
    if (object == nil) {
        NSString *reasonString = [NSString stringWithFormat:@"%s : value cannot be nil - use NSNull instead!", __PRETTY_FUNCTION__];
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reasonString userInfo:nil];
    }

    [self setValue:object forKey:key];
}

- (void)removeObjectForKey:(NSString *)key {
    [self removeValueForKey:key];
}

- (id)objectForKey:(NSString *)key {
    return [self valueForKey:key];
}

- (NSArray *)allObjects {
    __block id value;

    [self _performAccessToDatabaseWithBlock:^(sqlite3 *database) {
        value = [self _queryDatabase:database statement:[NSString stringWithFormat:@"SELECT key, value FROM %@", kKVDBTableName]];
    }];

    return value;
}

- (NSUInteger)count {
    __block NSInteger count = 0;

    [self _performAccessToDatabaseWithBlock:^(sqlite3 *database) {
        NSArray *records;

        records = [self _queryDatabase:database statement:[NSString stringWithFormat:@"Select count(*) as value from %@", kKVDBTableName]];

        if (records) {
            // TODO

            count = [[[records objectAtIndex:0] objectForKey:@"key"] intValue];
        }
    }];

    return count;
}

#pragma mark - Private API

- (void)_performAccessToDatabaseWithBlock:(void(^)(sqlite3 *database))databaseAccessBlock {
    sqlite3 *DB = [self _openDatabase];

    databaseAccessBlock(DB);

    [self _closeDatabase:DB];
}

#pragma mark - Private API: SQLITE methods

- (sqlite3 *)_openDatabase {
    sqlite3 *db = NULL;

    const char *dbpath = [self.file UTF8String];
    if (sqlite3_open(dbpath, &db) != SQLITE_OK) {
        @throw KVDBExceptionDBOpen();
    }

    return db;
}

- (void)_closeDatabase:(sqlite3 *)db {
    sqlite3_close(db);
}

/* Returns an array of rows */
- (NSArray *)_queryDatabase:(sqlite3 *)db statement:(NSString *)statement key:(NSString *)key {
    const char *sql = [statement UTF8String];
    const char *tail;
    sqlite3_stmt *stmt;

    if ((sqlite3_prepare_v2(db, sql, -1, &stmt, &tail) != SQLITE_OK)) {
        return nil; /* No data found. */
    }

    if (key) {
        sqlite3_bind_text(stmt, 1, [key UTF8String], -1, SQLITE_STATIC);
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

- (NSArray *)_queryDatabase:(sqlite3 *)db statement:(NSString *)statement {
    return [self _queryDatabase:db statement:statement key:nil];
}

/* Doesn't use blobs, so simply queries. */
- (void)_queryDatabase:(sqlite3 *)db statement:(NSString *)statement result:(void (^)(NSDictionary *))resultBlock {
    char *errMsg;

    int result = sqlite3_exec(db, [statement UTF8String], kvdbQueryCallback, (__bridge void *)(resultBlock), &errMsg);

    if (result != SQLITE_OK) {
        NSString *errorMsg = [[NSString alloc] initWithUTF8String:errMsg];

        sqlite3_free(errMsg);
        resultBlock([NSDictionary dictionaryWithObject:errorMsg forKey:@"error"]);
    }
}

/* Writes blobs, so it uses transactions */
- (void)_queryDatabase:(sqlite3 *)db statement:(NSString *)statement key:(NSString *)key data:(NSData *)data result:(void (^)(BOOL success, NSDictionary *))resultBlock {

    // @todo this is totally inflexible to argument count
    const char *sql = [statement UTF8String];
    sqlite3_stmt *stmt;

    if ((sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) == SQLITE_OK)) {
        sqlite3_bind_text(stmt, 1, [key UTF8String], -1, SQLITE_STATIC);
        sqlite3_bind_blob(stmt, 2, [data bytes], (int)[data length], SQLITE_STATIC);
    }

    int status = sqlite3_step(stmt);
    if (status != SQLITE_DONE) {
        const char *errMsg = sqlite3_errmsg(db);

        NSString *errorMsg = [[NSString alloc] initWithUTF8String:errMsg];

        resultBlock(NO, [NSDictionary dictionaryWithObject:errorMsg forKey:@"error"]);
    }

    sqlite3_finalize(stmt);

    resultBlock(YES, [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithLongLong:sqlite3_last_insert_rowid(db)], @"lastRowID",
                      [NSNumber numberWithInt:sqlite3_changes(db)], @"rowsChanged"
                      , nil]);
}

- (void)_createKVDBTableIfNotExistsInDB:(sqlite3 *)db {
    [self _queryDatabase:db statement:[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (key TEXT PRIMARY KEY, value BLOB)", kKVDBTableName]];
}

- (void)_ensureKVDBTableExistsInDB:(sqlite3 *)db {
    NSString *statement = @"SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;";

    [self _queryDatabase:db statement:statement result:^(NSDictionary *result) {
        if ([[result objectForKey:@"name"] isEqualToString:kKVDBTableName] == NO) {
            @throw [NSException exceptionWithName:@"SQLITEError" reason:[NSString stringWithFormat:@"There should have been a table called %@.", kKVDBTableName] userInfo:nil];
        }
    }];
}

#pragma mark - Data/query methods

/* Upsert via SO contributor Eric B;
 Updates or inserts safely.
 http://stackoverflow.com/questions/418898/sqlite-upsert-not-insert-or-replace/4253806#4253806
 */
- (NSString *)_upsertKeyQuery {
    return [NSString stringWithFormat:@"INSERT OR REPLACE INTO `%@` (`key`,`value`)" // table
            "VALUES ( ?, ?); COMMIT;",
            kKVDBTableName];
}

- (NSString *)_selectKeyQuery {
    return [NSString stringWithFormat:@"SELECT key, value FROM %@ WHERE key= ?", kKVDBTableName];
}

- (NSString *)_deleteKeyQuery {
    return [NSString stringWithFormat:@"DELETE FROM %@ WHERE key= ?", kKVDBTableName];
}


/* Call this function with a sqlite3_blob* initialized to NULL. */
- (void)_writeObject:(id)objC inDatabase:(sqlite3*)DB toBlob:(sqlite3_blob**)blob {

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

    NSUInteger byteCt = [data length];

    Byte *byteData = (Byte *)malloc(byteCt);

    memcpy(byteData, [data bytes], byteCt);
    sqlite3_blob_write(*blob, byteData, (int)byteCt, 0);

    free(byteData);
}

/* Call this function with a sqlite3_blob * initialized to NULL. */
- (NSData *)_readBlobFromDatabaseNamed:(NSString *)dbName tableName:(NSString *)tableName columnName:(NSString *)columnName rowID:(sqlite3_int64)rowID blob:(sqlite3_blob **)blob {
    if (*blob != NULL) {
        @throw [NSException exceptionWithName:@"SQLITEError" reason:@"Can only read to NULL blobs." userInfo:nil];
    }

    int status = sqlite3_blob_open([self _openDatabase], [dbName UTF8String], [tableName UTF8String], [columnName UTF8String], rowID, 0 /* Open for reading */, blob);

    if (status != SQLITE_OK) {
        @throw KVDBExceptionDBRead();
    }

    int byteCt = sqlite3_blob_bytes(*blob);
    Byte byteBuff[byteCt];

    return [NSData dataWithBytes:byteBuff length:byteCt];
}

- (NSData *)archiveObject:(id)object {
    return [NSKeyedArchiver archivedDataWithRootObject:object];
}

- (id)unarchiveData:(NSData *)data {
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

        if ([columnName isEqualToString:@"value"] == NO) {
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
    
    KVDictBlock objcBlk = (__bridge KVDictBlock)(resultBlock);
    
    objcBlk(row);
    
    return 0;
}
