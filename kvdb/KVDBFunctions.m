#import "KVDBFunctions.h"

NSString * KVDocumentsDirectory(void) {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
}

NSException * KVDBExceptionWrite(void) {
    return [NSException exceptionWithName:@"WriteError" reason:@"Couldn't write to NSDocuments Directory." userInfo:nil];
}

NSException * KVDBExceptionDBWrite(void) {
    return [NSException exceptionWithName:@"SQLITEError" reason:@"Couldn't insert/update into database at point." userInfo:nil];
}

NSException * KVDBExceptionDBRead(void) {
    return [NSException exceptionWithName:@"SQLITEError" reason:@"Couldn't read database at point." userInfo:nil];
}

NSException * KVDBExceptionDBTable(void) {
    return [NSException exceptionWithName:@"SQLITEError" reason:@"Couldn't create table." userInfo:nil];
}

NSException * KVDBExceptionDBOpen(void) {
    return [NSException exceptionWithName:@"SQLITEError" reason:@"Couldn't open sqlite db." userInfo:nil];
}

NSException * KVDBExceptionNoCoding(id obj) {
    return [NSException exceptionWithName:@"SQLITEError"
                                   reason:[NSString stringWithFormat:@"Can't write objects of class `%@` to DB that do not conform to the NSCoding protocol.", NSStringFromClass([obj class])]
                                 userInfo:[NSDictionary dictionaryWithObject:obj forKey:@"object"]];
}
