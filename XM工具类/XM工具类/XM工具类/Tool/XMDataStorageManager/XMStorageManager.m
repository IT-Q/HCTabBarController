//
//  StorageManager.m
//  TGO2
//
//  Created by  YangShengchao on 14-2-14.
//  Copyright (c) 2014年  YangShengchao. All rights reserved.
//

#import "XMStorageManager.h"
#define kCommonDirectoryName    @"Common/"

@interface XMStorageManager ()

@property (nonatomic, copy) NSString *userDir;
@property (nonatomic, copy) NSDictionary *appConfigDictionary;
@property (nonatomic, copy) NSDictionary *appDebugConfigDictionary;

@end

@implementation XMStorageManager

+ (instancetype)sharedInstance {
    
    static XMStorageManager *mgr = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mgr = [[self alloc] init];
    });
    return mgr;
}

- (id)init {
    self = [super init];
    if (self) {
        self.directoryPathOfHome = [XMFileOperate DirectoryPathOfHome];
        self.directoryPathOfDocuments = [XMFileOperate DirectoryPathOfDocuments];
        self.directoryPathOfLibrary = [XMFileOperate DirectoryPathOfLibrary];
        self.directoryPathOfLibraryCaches = [XMFileOperate DirectoryPathOfLibraryCaches];
        self.directoryPathOfLibraryPreferences = [XMFileOperate DirectoryPathOfLibraryPreferences];
        self.directoryPathOfTmp = [XMFileOperate DirectoryPathOfTmp];
        
        self.userDir = kCommonDirectoryName;
        [self ensureCommonDirectories];
    }
    return self;
}
/**
 *  设置用户id
 *
 *  @param userId 用户id
 */
- (void)setUserId:(NSString *)userId {
    if ( ! [self isEmpty:userId]) {
        self.userDir = [userId stringByAppendingString:([userId hasSuffix:@"/"] ? @"" : @"/")];//确保最后一个字符是'/'
    }
    else {
        self.userDir = kCommonDirectoryName;
    }
    
    [self ensureUserDirectories];
}


#pragma mark - Documents目录下的文件和目录路径

/**
 *  /Documents/UserId/
 *
 *  @return 用户目录
 */
- (NSString *)directoryPathOfDocumentsByUserId {
    return [self.directoryPathOfDocuments stringByAppendingPathComponent:self.userDir];
}

/**
 *  /Documents/UserId/UserSettings.archive
 *
 *  @return 用户配置信息文件路径
 */
- (NSString *)filePathOfUserSettings {
    return [[self directoryPathOfDocumentsByUserId] stringByAppendingPathComponent:@"UserSettings.archive"];
}

/**
 *  /Documents/Common/
 *
 *  @return 公共根目录
 */
- (NSString *)directoryPathOfDocumentsCommon {
    return [self.directoryPathOfDocuments stringByAppendingPathComponent:kCommonDirectoryName];
}

/**
 *  /Documents/Common/CommonSettings.archive
 *
 *  @return 公共配置信息文件路径
 */
- (NSString *)filePathOfCommonSettings {
    return [[self directoryPathOfDocumentsCommon] stringByAppendingPathComponent:@"CommonSettings.archive"];
}

/**
 *  /Documents/Log/
 *
 *  @return 公共日志文件目录
 */
- (NSString *)directoryPathOfDocumentsLog {
    return [self.directoryPathOfDocuments stringByAppendingPathComponent:@"Log/"];
}



#pragma mark - Library目录下的文件和目录路径

/**
 *  /Library/Caches/UserId/
 *
 *  @return 用户的缓存目录
 */
- (NSString *)directoryPathOfLibraryCachesByUserId {
    return [self.directoryPathOfLibraryCaches stringByAppendingPathComponent:self.userDir];
}

/**
 *  /Library/Caches/UserId/Pics/
 *
 *  @return 用户图片目录
 */
- (NSString *)directoryPathOfPicByUserId {
    return [[self directoryPathOfLibraryCachesByUserId] stringByAppendingPathComponent:@"Pics/"];
}

/**
 *  /Library/Caches/UserId/Audioes/
 *
 *  @return 用户音频目录
 */
- (NSString *)directoryPathOfAudioByUserId {
    return [[self directoryPathOfLibraryCachesByUserId] stringByAppendingPathComponent:@"Audioes/"];
}

/**
 *  /Library/Caches/UserId/Videoes/
 *
 *  @return 用户视频目录
 */
- (NSString *)directoryPathOfVideoByUserId {
    return [[self directoryPathOfLibraryCachesByUserId] stringByAppendingPathComponent:@"Videoes/"];
}

/**
 *  /Library/Caches/Common/
 *
 *  @return 公共缓存目录
 */
- (NSString *)directoryPathOfLibraryCachesCommon {
    return [self.directoryPathOfLibraryCaches stringByAppendingPathComponent:kCommonDirectoryName];
}




#pragma mark - 公共配置文件存取
/**
 *  设置config某个key对应的value
 *
 */
- (void)setConfigValue:(NSObject *)value forKey:(NSString *)key {
    [self setConfigWithValuesAndKeys:value, key, nil];
}
/**
 *  设置config的通用方法
 *  overwrite = no
 *
 *  @param firstObject object+key...
 */
- (void)setConfigWithValuesAndKeys:(id)firstObject, ... NS_REQUIRES_NIL_TERMINATION {
    NSMutableArray *keys = [NSMutableArray array];
    NSMutableArray *values = [NSMutableArray array];
    
    va_list args;
    va_start(args, firstObject);
    for (id value = firstObject; value != nil; value = va_arg(args, id)) {
        id key = va_arg(args, id);
        [values addObject:value];
        [keys addObject:key];
    }
    va_end(args);
    
    NSInteger valueCount = [values count];
    if (valueCount != [keys count]) {
        NSLog(@"set config error : objects and keys don’t have the same number of elements.");
    }
    else {
        NSMutableDictionary *configDictionary = [NSMutableDictionary dictionary];
        for(int index = 0; index < valueCount; index ++) {
            [configDictionary setObject:[values objectAtIndex:index] forKey:[keys objectAtIndex:index]];
        }
        [self archiveDictionary:configDictionary toFilePath:[self filePathOfCommonSettings] overwrite:NO];
    }
    
}
/**
 *  获取config中key对应的value
 *
 *  @param key
 *
 *  @return value
 */
- (id)configValueForKey:(NSString *)key {
    if ([self isEmpty:key]) {
        return nil;
    }
    
    NSDictionary *config = [self unarchiveDictionaryFromFilePath:[self filePathOfCommonSettings]];
    return config[key];
}


#pragma mark - 用户配置文件存取
/**
 *  设置user的某个key对应的value
 *
 *  @param value
 *  @param key
 */
- (void)setUserConfigValue:(NSObject *)value forKey:(NSString *)key {
    [self setUserConfigWithValuesAndKeys:value, key, nil];
}
/**
 *  设置user的key和value的通用方法
 *  overwrite = no
 *
 *  @param firstObject
 */
- (void)setUserConfigWithValuesAndKeys:(id)firstObject, ... NS_REQUIRES_NIL_TERMINATION {
    NSMutableArray *keys = [NSMutableArray array];
    NSMutableArray *values = [NSMutableArray array];
    
    va_list args;
    va_start(args, firstObject);
    for (id value = firstObject; value != nil; value = va_arg(args, id)) {
        id key = va_arg(args, id);
        [values addObject:value];
        [keys addObject:key];
    }
    va_end(args);
    
    NSInteger valueCount = [values count];
    if (valueCount != [keys count]) {
        NSLog(@"set config error : objects and keys don’t have the same number of elements.");
    }
    else {
        NSMutableDictionary *configDictionary = [NSMutableDictionary dictionary];
        for(int index = 0; index < valueCount; index ++) {
            [configDictionary setObject:[values objectAtIndex:index] forKey:[keys objectAtIndex:index]];
        }
        [self archiveDictionary:configDictionary toFilePath:[self filePathOfUserSettings] overwrite:NO];
    }
}
/**
 *  获取user的某个key
 */
- (id)userConfigValueForKey:(NSString *)key {
    if ([self isEmpty:key]) {
        return nil;
    }
    
    NSDictionary *userConfig = [self unarchiveDictionaryFromFilePath:[self filePathOfUserSettings]];
    return userConfig[key];
}


#pragma mark - 序列化和反序列化归档文件
/**
 *  序列化dict
 *  overwrite = no
 *
 *  @param dicionary 需要缓存的对象
 *  @param filePath 缓存文件的对象
 */
- (BOOL)archiveDictionary:(NSDictionary *)dicionary toFilePath:(NSString *)filePath {
    return [self archiveDictionary:dicionary toFilePath:filePath overwrite:NO];
}
/**
 *  序列化通用方法
 *
 *  @param dicionary 需要缓存的对象
 *  @param filePath 缓存文件的对象
 *  @param overwrite YES-会把相同filePath的dict替换成新的 NO-相同的filePath合并（里面相同key的值会被新的value代替）
 */
- (BOOL)archiveDictionary:(NSDictionary *)dicionary toFilePath:(NSString *)filePath overwrite:(BOOL)overwrite {
    if (overwrite) {
        return [NSKeyedArchiver archiveRootObject:dicionary toFile:filePath];
    }
    else {
        NSMutableDictionary *allDictionary = [NSMutableDictionary dictionaryWithCapacity:[dicionary count]];
        [allDictionary addEntriesFromDictionary:[self unarchiveDictionaryFromFilePath:filePath]];
        [allDictionary addEntriesFromDictionary:dicionary];
        return [NSKeyedArchiver archiveRootObject:allDictionary toFile:filePath];
    }
}

/**
 序列化数组

 @param array 缓存对象
 @param filePath 缓存文件路径
 */
- (BOOL)archiveArray:(NSArray *)array toFilePath:(NSString *)filePath
{
    return [NSKeyedArchiver archiveRootObject:array toFile:filePath];
}

/**
 *  反序列化
 *
 *  @param filePath 缓存文件的对象
 */
- (NSDictionary *)unarchiveDictionaryFromFilePath:(NSString *)filePath {
    NSDictionary *dictionary;
    @try {
        dictionary = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    }
    @catch(NSException *exception) {
        NSLog(@"unarchive error:%@", [exception debugDescription]);
    }
    @finally {

    }
    return dictionary;
}
/**
 *  反序列化
 *
 *  @param filePath 缓存文件的对象
 *
 */
- (NSArray *)unarchiveArrayFromFilePath:(NSString *)filePath
{
    NSArray *array;
    @try {
        array = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    }@catch(NSException *exception){
        NSLog(@"unarchive error:%@", [exception debugDescription]);
    }@finally {

    }
    return array;
}

#pragma mark - 缓存清理
/**
 *  删除整个目录/Library/Caches下所有的内容，并确保所有缓存目录都存在
 */
- (void)clearLibraryCaches {
    [XMFileOperate clearDirectoryPath:self.directoryPathOfLibraryCaches];
    [XMFileOperate clearDirectoryPath:self.directoryPathOfDocumentsLog];
    [self ensureCommonDirectories];
    [self ensureUserDirectories];
}

#pragma mark - 私有方法
/**
 *  确保公共缓存目录的存在
 */
- (void)ensureCommonDirectories {
    [XMFileOperate ensureDirectory:[self directoryPathOfDocumentsCommon]];
    [XMFileOperate ensureDirectory:[self directoryPathOfDocumentsLog]];
    [XMFileOperate ensureDirectory:[self directoryPathOfLibraryCachesCommon]];
}
/**
 *  确保用户缓存目录的存在
 */
- (void)ensureUserDirectories {
    [XMFileOperate ensureDirectory:[self directoryPathOfDocumentsByUserId]];
    [XMFileOperate ensureDirectory:[self directoryPathOfLibraryCachesByUserId]];
    [XMFileOperate ensureDirectory:[self directoryPathOfAudioByUserId]];
    [XMFileOperate ensureDirectory:[self directoryPathOfVideoByUserId]];
    [XMFileOperate ensureDirectory:[self directoryPathOfPicByUserId]];
}
/**
 *  判断字符串是否为空
 *
 *  @param string 字符串
 *
 *  @return YES/NO
 */
- (BOOL)isEmpty:(NSString *)string {
    if ( ! string) {
        return YES;
    }
    return !([string length] && [[string stringByReplacingOccurrencesOfString:@" " withString:@""] length]);
}


@end
