//
//  KVDB_Protected.h
//  kvdbApp
//
//  Created by Stanislaw Pankevich on 9/7/13.
//  Copyright (c) 2013 Stanislaw Pankevich. All rights reserved.
//

#import "KVDB.h"

@interface KVDB ()

@property (nonatomic) dispatch_queue_t isolationQueue;
@property BOOL isAccessToDatabaseIsolated;
@property sqlite3 *isolatedAccessDatabase;
- (void)_performAccessToDatabaseWithBlock:(void(^)(sqlite3 *database))databaseAccessBlock;

@property (nonatomic, retain) NSString *file;


- (sqlite3 *)_openDatabase;
- (void)_closeDatabase:(sqlite3 *)db;
- (NSArray *)_queryDatabase:(sqlite3 *)db statement:(NSString *)statement;
- (void)_queryDatabase:(sqlite3 *)db statement:(NSString *)statement result:(void (^)(NSDictionary *))resultBlock;
- (void)_queryDatabase:(sqlite3 *)db statement:(NSString *)statement data:(NSData*)data result:(void (^)(BOOL success, NSDictionary * result))resultBlock;

- (void)_createKVDBTableIfNotExistsInDB:(sqlite3 *)db;
- (void)_ensureKVDBTableExistsInDB:(sqlite3 *)db;

- (NSString *)_upsertQueryWithKey:(NSString *)key;
- (NSString *)_selectQueryForKey:(NSString *)key;
- (NSString *)_deleteQueryForKey:(NSString *)key;
- (void)_writeObject:(id)objC inDatabase:(sqlite3 *)DB toBlob:(sqlite3_blob **)blob;
- (NSData*)_readBlobFromDatabaseNamed:(NSString *)dbName tableName:(NSString *)tableName columnName:(NSString *)columnName rowID:(sqlite3_int64)rowID blob:(sqlite3_blob **)blob;

- (NSData*)archiveObject:(id)object;
- (id)unarchiveData:(NSData*)data;

@end
