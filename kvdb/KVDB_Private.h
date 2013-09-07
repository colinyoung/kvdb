//
//  KVDB_Protected.h
//  kvdbApp
//
//  Created by Stanislaw Pankevich on 9/7/13.
//  Copyright (c) 2013 Stanislaw Pankevich. All rights reserved.
//

#import "KVDB.h"

@interface KVDB ()

@property (nonatomic, retain) NSString *file;

- (void)createDBFile;
- (sqlite3*)openDatabase;
- (void)closeDatabase:(sqlite3*)db;
- (NSArray*)queryDatabase:(sqlite3 *)db statement:(NSString *)statement;
- (void)queryDatabase:(sqlite3 *)db statement:(NSString *)statement result:(void (^)(NSDictionary *))resultBlock;
- (void)queryDatabase:(sqlite3 *)db statement:(NSString *)statement data:(NSData*)data result:(void (^)(BOOL success, NSDictionary * result))resultBlock;
- (void)ensureThatKVDBTableExistsInDB:(sqlite3 *)db;

- (NSString *)_upsertQueryWithKey:(NSString *)key;
- (NSString *)_selectQueryForKey:(NSString *)key;
- (NSString *)_deleteQueryForKey:(NSString *)key;
- (void)_writeObject:(id)objC inDatabase:(sqlite3*)DB toBlob:(sqlite3_blob**)blob;
- (NSData*)_readBlobFromDatabaseNamed:(NSString *)dbName tableName:(NSString *)tableName columnName:(NSString *)columnName rowID:(NSUInteger)rowID blob:(sqlite3_blob**)blob;

- (NSData*)archiveObject:(id)object;
- (id)unarchiveData:(NSData*)data;

@end
