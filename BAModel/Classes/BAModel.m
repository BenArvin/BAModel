//
//  BAModel.m
//  BAModel
//
//  Created by BenArvin on 2019/4/11.
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "BAModel.h"
#import <objc/runtime.h>
#import <CoreGraphics/CoreGraphics.h>

@interface BAModelHelper : NSObject

// usr/include/objc/runtime.h
@property (nonatomic) NSString *intClassStr;//_C_INT
@property (nonatomic) NSString *uintClassStr;//_C_UINT
@property (nonatomic) NSString *longClassStr;//_C_LNG
@property (nonatomic) NSString *ulongClassStr;//_C_ULNG
@property (nonatomic) NSString *longlongClassStr;//_C_LNG_LNG
@property (nonatomic) NSString *ulonglongClassStr;//_C_ULNG_LNG
@property (nonatomic) NSString *floatClassStr;//_C_FLT
@property (nonatomic) NSString *doubleClassStr;//_C_DBL
@property (nonatomic) NSString *boolClassStr;//_C_BOOL
@property (nonatomic) NSString *rectClassStr;
@property (nonatomic) NSString *pointClassStr;
@property (nonatomic) NSString *sizeClassStr;
@property (nonatomic) NSString *rangeClassStr;

@property (nonatomic) NSArray *defaultIgnoredProperties;

@end

@implementation BAModelHelper

- (instancetype)init {
    self = [super init];
    if (self) {
        _intClassStr = [NSString stringWithUTF8String:@encode(int)];
        _uintClassStr = [NSString stringWithUTF8String:@encode(unsigned int)];
        _longClassStr = [NSString stringWithUTF8String:@encode(long)];
        _ulongClassStr = [NSString stringWithUTF8String:@encode(unsigned long)];
        _longlongClassStr = [NSString stringWithUTF8String:@encode(long long)];
        _ulonglongClassStr = [NSString stringWithUTF8String:@encode(unsigned long long)];
        _floatClassStr = [NSString stringWithUTF8String:@encode(float)];
        _doubleClassStr = [NSString stringWithUTF8String:@encode(double)];
        _boolClassStr = [NSString stringWithUTF8String:@encode(bool)];

        _rectClassStr = [NSString stringWithUTF8String:@encode(CGRect)];
        _pointClassStr = [NSString stringWithUTF8String:@encode(CGPoint)];
        _sizeClassStr = [NSString stringWithUTF8String:@encode(CGSize)];
        _rangeClassStr = [NSString stringWithUTF8String:@encode(NSRange)];
        
        _defaultIgnoredProperties = @[
            NSStringFromSelector(@selector(hash)),
            NSStringFromSelector(@selector(description)),
            NSStringFromSelector(@selector(debugDescription)),
        ];
    }
    return self;
}

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static BAModelHelper *helper;
    dispatch_once(&onceToken, ^{
        helper = [[BAModelHelper alloc] init];
    });
    return helper;
}

+ (NSString *)dateToStr:(NSDate *)date {
    if (!date) {
        return nil;
    }
    return [NSString stringWithFormat:@"%.9f", [date timeIntervalSince1970]];
}

+ (NSDate *)strToDate:(NSString *)str {
    if (!str) {
        return nil;
    }
    return [NSDate dateWithTimeIntervalSince1970:str.doubleValue];
}

+ (BOOL)isObjectClass:(NSString *)classStr {
    if (!classStr || classStr.length < 3) {
        return NO;
    }
    if ([classStr rangeOfString:@"@\""].location == 0) {
        return YES;
    } else {
        return NO;
    }
}

+ (Class)getObjectClass:(NSString *)classStr {
    if (![self isObjectClass:classStr]) {
        return nil;
    }
    NSString *newClassStr = [classStr substringWithRange:NSMakeRange(2, classStr.length - 3)];
    return NSClassFromString(newClassStr);
}

@end


@implementation NSObject (BAModel)

+ (instancetype)ba_newWithDictionary:(NSDictionary *)dictionary {
    if (!dictionary) {
        return nil;
    }
    id result = [[self alloc] init];
    [result ba_loadFromDic:dictionary];
    return result;
}

- (instancetype)ba_initWithDictionary:(NSDictionary *)dictionary {
    id result = [self init];
    if (result) {
        [result ba_loadFromDic:dictionary];
    }
    return result;
}

- (NSDictionary *)ba_toDictionary {
    return [self ba_codeObject];
}

+ (instancetype)ba_newWithJsonStr:(NSString *)jsonStr {
    NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    if (jsonData.length <= 0) {
        return nil;
    }
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
    if (err) {
        return nil;
    }
    id result = [[self alloc] init];
    [result ba_loadFromDic:dic];
    return result;
}

- (instancetype)ba_initWithJsonStr:(NSString *)jsonStr {
    id result = [self init];
    if (result) {
        NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
        if (jsonData.length > 0) {
            NSError *err;
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
            if (!err) {
                [self ba_loadFromDic:dic];
            }
        }
    }
    return result;
}

- (NSString *)ba_toJsonStr {
    NSDictionary *dic = [self ba_codeObject];
    if (!dic) {
        return nil;
    }
    NSError *err;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:&err];
    if (err) {
        return nil;
    }
    if (!jsonData) {
        return nil;
    }
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

#pragma mark - private methods
- (void)ba_loadFromDic:(NSDictionary *)dic {
    if (!dic || [self class] == [NSObject class]) {
        return;
    }

    NSMutableDictionary *propertyInfos = [[NSMutableDictionary alloc] init];
    Class currentClass = [self class];
    while (1) {
        if (currentClass == [NSObject class]) {
            break;
        }
        unsigned int propertyCount;
        objc_property_t *propertyList = class_copyPropertyList(currentClass, &propertyCount);
        for (int i=0; i<propertyCount; i++) {
            objc_property_t propertyItem = propertyList[i];
            NSString *propertyNameString = [NSString stringWithUTF8String:property_getName(propertyItem)];
            NSString *propertyClassString = [self ba_propertyClassStringFromPropertyAttributes:propertyItem];
            if (propertyNameString && propertyClassString) {
                [propertyInfos setObject:propertyClassString forKey:propertyNameString];
            }
        }
        currentClass = [currentClass superclass];
    }

    NSArray *ignoredProperties = nil;
    if ([self respondsToSelector:@selector(ba_ignoredProperties)]) {
        ignoredProperties = [self performSelector:@selector(ba_ignoredProperties)];
    }
    NSDictionary *genericClasses = nil;
    if ([self respondsToSelector:@selector(ba_containerPropertyGenericClass)]) {
        genericClasses = [self performSelector:@selector(ba_containerPropertyGenericClass)];
    }

    NSEnumerator *enumerator = [dic keyEnumerator];
    id key;
    while ((key = [enumerator nextObject])) {
        if (![key isKindOfClass:[NSString class]]) {
            continue;
        }
        NSString *propertyName = [self ba_propertyNameFromKey:key];
        if (!propertyName || propertyName.length == 0 || [ignoredProperties containsObject:propertyName]) {
            continue;
        }
        id value = [dic valueForKey:key];

        NSString *propertyClassName = [propertyInfos objectForKey:propertyName];
        if (!propertyClassName || propertyClassName.length == 0) {
            continue;
        }
        Class propertyClass = [BAModelHelper getObjectClass:propertyClassName];
        if (propertyClass) {
            if ([propertyClass isSubclassOfClass:[NSString class]]) {
                if (propertyClass == [NSMutableString class]) {
                    [self setValue:[NSMutableString stringWithString:(NSString *)value] forKey:propertyName];
                } else {
                    [self setValue:value forKey:propertyName];
                }
            } else if ([propertyClass isSubclassOfClass:[NSData class]]) {
                if (propertyClass == [NSMutableData class]) {
                    [self setValue:[NSMutableData dataWithData:(NSData *)value] forKey:propertyName];
                } else {
                    [self setValue:value forKey:propertyName];
                }
            } else if ([propertyClass isSubclassOfClass:[NSNumber class]]) {
                [self setValue:value forKey:propertyName];
            } else if ([propertyClass isSubclassOfClass:[NSDate class]]) {
                [self setValue:[NSDate dateWithTimeIntervalSince1970:((NSString *)value).doubleValue] forKey:propertyName];
            } else if ([propertyClass isSubclassOfClass:[NSArray class]]) {
                Class genericClass = [genericClasses objectForKey:propertyName];
                if (!genericClass || ![genericClass isKindOfClass:[NSObject class]]) {
                    [self setValue:value forKey:propertyName];
                    continue;
                }
                NSMutableArray *newValue = [[NSMutableArray alloc] init];
                for (id item in (NSArray *)value) {
                    id newItem = [[genericClass alloc] init];
                    [newItem ba_loadFromDic:item];
                    [newValue addObject:newItem];
                }
                [self setValue:newValue forKey:propertyName];
            } else if ([propertyClass isSubclassOfClass:[NSDictionary class]]) {
                Class genericClass = [genericClasses objectForKey:propertyName];
                if (!genericClass || ![genericClass isKindOfClass:[NSObject class]]) {
                    [self setValue:value forKey:propertyName];
                    continue;
                }
                NSMutableDictionary *newValue = [[NSMutableDictionary alloc] init];
                NSEnumerator *innerEnumerator = [(NSDictionary *)value keyEnumerator];
                id innerKey;
                while ((innerKey = [innerEnumerator nextObject])) {
                    if (![innerKey isKindOfClass:[NSString class]]) {
                        continue;
                    }
                    id oldItem = [(NSDictionary *)value objectForKey:innerKey];
                    id newItem = [[genericClass alloc] init];
                    [newItem ba_loadFromDic:oldItem];
                    [newValue setValue:innerKey forKey:newItem];
                }
                [self setValue:newValue forKey:propertyName];
            } else if ([propertyClass isKindOfClass:[NSObject class]]) {
                id newVlaue = [[propertyClass alloc] init];
                [newVlaue ba_loadFromDic:value];
                [self setValue:newVlaue forKey:propertyName];
            }
        } else {
            if ([propertyClassName isEqualToString:[BAModelHelper shared].boolClassStr]
                || [propertyClassName isEqualToString:[BAModelHelper shared].intClassStr]) {
                [self setValue:@(((NSNumber *)value).intValue) forKey:propertyName];
            } else if ([propertyClassName isEqualToString:[BAModelHelper shared].uintClassStr]) {
                [self setValue:@(((NSNumber *)value).unsignedIntValue) forKey:propertyName];
            } else if ([propertyClassName isEqualToString:[BAModelHelper shared].longClassStr]) {
                [self setValue:@(((NSNumber *)value).longValue) forKey:propertyName];
            } else if ([propertyClassName isEqualToString:[BAModelHelper shared].ulongClassStr]) {
                [self setValue:@(((NSNumber *)value).unsignedLongValue) forKey:propertyName];
            } else if ([propertyClassName isEqualToString:[BAModelHelper shared].longlongClassStr]) {
                [self setValue:@(((NSNumber *)value).longLongValue) forKey:propertyName];
            } else if ([propertyClassName isEqualToString:[BAModelHelper shared].ulonglongClassStr]) {
                [self setValue:@(((NSNumber *)value).unsignedLongLongValue) forKey:propertyName];
            } else if ([propertyClassName isEqualToString:[BAModelHelper shared].floatClassStr]) {
                [self setValue:@(((NSNumber *)value).floatValue) forKey:propertyName];
            } else if ([propertyClassName isEqualToString:[BAModelHelper shared].doubleClassStr]) {
                [self setValue:@(((NSNumber *)value).doubleValue) forKey:propertyName];
            } else if ([propertyClassName isEqualToString:[BAModelHelper shared].rectClassStr]) {
                CGRect rectValue = [self ba_strToRect:value];
                SEL sel = NSSelectorFromString([self ba_setSelNameFromGetSelName:propertyName]);
                void *params[1] = {&rectValue};
                [self ba_callFuncDynamic:false targetClass:[self class] targetInstance:self selector:sel paramsCount:1 params:params result:nil];
            } else if ([propertyClassName isEqualToString:[BAModelHelper shared].pointClassStr]) {
                CGPoint pointValue = [self ba_strToPoint:value];
                SEL sel = NSSelectorFromString([self ba_setSelNameFromGetSelName:propertyName]);
                void *params[1] = {&pointValue};
                [self ba_callFuncDynamic:false targetClass:[self class] targetInstance:self selector:sel paramsCount:1 params:params result:nil];
            } else if ([propertyClassName isEqualToString:[BAModelHelper shared].sizeClassStr]) {
                CGSize sizeValue = [self ba_strToSize:value];
                SEL sel = NSSelectorFromString([self ba_setSelNameFromGetSelName:propertyName]);
                void *params[1] = {&sizeValue};
                [self ba_callFuncDynamic:false targetClass:[self class] targetInstance:self selector:sel paramsCount:1 params:params result:nil];
            } else if ([propertyClassName isEqualToString:[BAModelHelper shared].rangeClassStr]) {
                NSRange rangeValue = [self ba_strToRange:value];
                SEL sel = NSSelectorFromString([self ba_setSelNameFromGetSelName:propertyName]);
                void *params[1] = {&rangeValue};
                [self ba_callFuncDynamic:false targetClass:[self class] targetInstance:self selector:sel paramsCount:1 params:params result:nil];
            }
        }
    }
}

- (id)ba_codeObject {
    if ([self class] == [NSObject class]) {
        return nil;
    }
    if ([self isKindOfClass:[NSString class]]
        || [self isKindOfClass:[NSData class]]
        || [self isKindOfClass:[NSNumber class]]) {
        return self;
    } else if ([self isKindOfClass:[NSDate class]]) {
        return [BAModelHelper dateToStr:(NSDate *)self];
    } else if ([self isKindOfClass:[NSArray class]]) {
        NSMutableArray *result = nil;
        for (id arrayItem in (NSArray *)self) {
            if (!result) {
                result = [[NSMutableArray alloc] init];
            }
            id convertedItem = [arrayItem ba_codeObject];
            if (convertedItem) {
                [result addObject:convertedItem];
            }
        }
        return result;
    } else if ([self isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *result = nil;
        NSDictionary *dictionary = (NSDictionary *)self;
        for (id keyItem in [dictionary allKeys]) {
            id valueItem = [dictionary objectForKey:keyItem];
            id convertedKey = [keyItem ba_codeObject];
            id convertedValue = [valueItem ba_codeObject];
            if (!convertedKey || !convertedValue) {
                continue;
            }
            if (!result) {
                result = [[NSMutableDictionary alloc] init];
            }
            [result setObject:convertedValue forKey:convertedKey];
        }
        return result;
    } else {
        __block NSMutableDictionary *result = nil;
        
        void(^setDicObjectBlock)(id, id) = ^(id value, id key) {
            if (!value || !key) {
                return;
            }
            if (!result) {
                result = [[NSMutableDictionary alloc] init];
            }
            [result setObject:value forKey:key];
        };
        NSArray *ignoredProperties = nil;
        if ([self respondsToSelector:@selector(ba_ignoredProperties)]) {
            ignoredProperties = [self performSelector:@selector(ba_ignoredProperties)];
        }
        Class currentClass = [self class];
        while (1) {
            if (currentClass == [NSObject class]) {
                break;
            }
            
            unsigned int propertyCount;
            objc_property_t *propertyList = class_copyPropertyList(currentClass, &propertyCount);
            for (int i=0; i<propertyCount; i++) {
                objc_property_t propertyItem = propertyList[i];
                NSString *propertyNameString = [NSString stringWithUTF8String:property_getName(propertyItem)];
                if ([[BAModelHelper shared].defaultIgnoredProperties containsObject:propertyNameString]) {
                    continue;
                }
                if ([ignoredProperties containsObject:propertyNameString]) {
                    continue;
                }
                NSString *keyString = [self ba_keyFromPropertyName:propertyNameString];
                if (!keyString || keyString.length == 0) {
                    continue;
                }
                NSString *propertyClassString = [self ba_propertyClassStringFromPropertyAttributes:propertyItem];
                if (!propertyClassString || propertyClassString.length == 0) {
                    continue;
                }
                id propertyValue = [self valueForKey:propertyNameString];
                if ([BAModelHelper isObjectClass:propertyClassString]) {
                    setDicObjectBlock([propertyValue ba_codeObject], keyString);
                } else {
                    if ([propertyClassString isEqualToString:[BAModelHelper shared].boolClassStr]
                        || [propertyClassString isEqualToString:[BAModelHelper shared].intClassStr]
                        || [propertyClassString isEqualToString:[BAModelHelper shared].uintClassStr]
                        || [propertyClassString isEqualToString:[BAModelHelper shared].longClassStr]
                        || [propertyClassString isEqualToString:[BAModelHelper shared].ulongClassStr]
                        || [propertyClassString isEqualToString:[BAModelHelper shared].longlongClassStr]
                        || [propertyClassString isEqualToString:[BAModelHelper shared].ulonglongClassStr]
                        || [propertyClassString isEqualToString:[BAModelHelper shared].floatClassStr]
                        || [propertyClassString isEqualToString:[BAModelHelper shared].doubleClassStr]) {
                        setDicObjectBlock(propertyValue, keyString);
                    } else if ([propertyClassString isEqualToString:[BAModelHelper shared].rectClassStr]) {
                        CGRect rectValue;
                        [self ba_callFuncDynamic:false targetClass:[self class] targetInstance:self selector:NSSelectorFromString(propertyNameString) paramsCount:0 params:nil result:&rectValue];
                        setDicObjectBlock([self ba_rectToStr:rectValue], keyString);
                    } else if ([propertyClassString isEqualToString:[BAModelHelper shared].pointClassStr]) {
                        CGPoint pointValue;
                        [self ba_callFuncDynamic:false targetClass:[self class] targetInstance:self selector:NSSelectorFromString(propertyNameString) paramsCount:0 params:nil result:&pointValue];
                        setDicObjectBlock([self ba_pointToStr:pointValue], keyString);
                    } else if ([propertyClassString isEqualToString:[BAModelHelper shared].sizeClassStr]) {
                        CGSize sizeValue;
                        [self ba_callFuncDynamic:false targetClass:[self class] targetInstance:self selector:NSSelectorFromString(propertyNameString) paramsCount:0 params:nil result:&sizeValue];
                        setDicObjectBlock([self ba_sizeToStr:sizeValue], keyString);
                    } else if ([propertyClassString isEqualToString:[BAModelHelper shared].rangeClassStr]) {
                        NSRange rangeValue;
                        [self ba_callFuncDynamic:false targetClass:[self class] targetInstance:self selector:NSSelectorFromString(propertyNameString) paramsCount:0 params:nil result:&rangeValue];
                        setDicObjectBlock([self ba_rangeToStr:rangeValue], keyString);
                    }
                }
            }
            
            currentClass = [currentClass superclass];
        }
        return result;
    }
}

- (NSString *)ba_propertyNameFromKey:(NSString *)key {
    if (!key || key.length == 0) {
        return nil;
    }
    NSDictionary *nameKeyDictionary = nil;
    if ([self respondsToSelector:@selector(ba_customPropertyNames)]) {
        nameKeyDictionary = [self performSelector:@selector(ba_customPropertyNames)];
    }
    if (!nameKeyDictionary) {
        return key;
    }
    for (NSString *propertyName in nameKeyDictionary) {
        if ([[nameKeyDictionary objectForKey:propertyName] isEqualToString:key]) {
            return propertyName;
        }
    }
    return key;
}

- (NSString *)ba_keyFromPropertyName:(NSString *)propertyName {
    if (!propertyName || propertyName.length == 0) {
        return nil;
    }
    NSDictionary *nameKeyDictionary = nil;
    if ([self respondsToSelector:@selector(ba_customPropertyNames)]) {
        nameKeyDictionary = [self performSelector:@selector(ba_customPropertyNames)];
    }
    if (!nameKeyDictionary) {
        return propertyName;
    }
    NSString *key = [nameKeyDictionary objectForKey:propertyName];
    if (!key || key.length == 0) {
        return propertyName;
    } else {
        return key;
    }
}

- (NSString *)ba_propertyClassStringFromPropertyAttributes:(objc_property_t)property {
    objc_property_attribute_t *list = property_copyAttributeList(property, nil);
    return [NSString stringWithUTF8String:list[0].value];
}

- (void)ba_callFuncDynamic:(bool)classFunc targetClass:(Class)targetClass targetInstance:(id)targetInstance selector:(SEL)selector paramsCount:(int)paramsCount params:(void *[])params result:(void *)result {
    Class realTargetClass = targetClass;
    id realTargetInstance = targetInstance;
    if (classFunc) {
        realTargetClass = objc_getMetaClass([NSStringFromClass(targetClass) UTF8String]);
        realTargetInstance = targetClass;
    }
    NSMethodSignature *sig = [realTargetClass instanceMethodSignatureForSelector:selector];
    if (!sig) {
        return;
    }
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
    if (!invocation) {
        return;
    }
    invocation.target = realTargetInstance;
    invocation.selector = selector;
    
    for (int i=0; i<paramsCount; i++) {
        void *tmpParamItem = params[i];
        [invocation setArgument:tmpParamItem atIndex:(i+2)];
    }
    
    [invocation invoke];
    
//    const char *sigretun = sig.methodReturnType;
    NSUInteger siglength = sig.methodReturnLength;
    if (siglength != 0) {
//        if (strcmp(sigretun, "@") == 0) {
//            NSString *returnStr;
//            [invocation getReturnValue:&returnStr];
//        }
        if (result) {
            [invocation getReturnValue:result];
        }
    }
}

- (NSString *)ba_rectToStr:(CGRect)rect {
    return [[NSString alloc] initWithFormat:@"%f,%f,%f,%f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height];
}

- (CGRect)ba_strToRect:(NSString *)str {
    if (![str isKindOfClass:[NSString class]]) {
        return CGRectMake(0, 0, 0, 0);
    }
    NSArray <NSString *> *parts = [str componentsSeparatedByString:@","];
    if (parts.count != 4) {
        return CGRectMake(0, 0, 0, 0);
    }
    return CGRectMake(parts[0].floatValue, parts[1].floatValue, parts[2].floatValue, parts[3].floatValue);
}

- (NSString *)ba_pointToStr:(CGPoint)point {
    return [[NSString alloc] initWithFormat:@"%f,%f", point.x, point.y];
}

- (CGPoint)ba_strToPoint:(NSString *)str {
    if (![str isKindOfClass:[NSString class]]) {
        return CGPointMake(0, 0);
    }
    NSArray <NSString *> *parts = [str componentsSeparatedByString:@","];
    if (parts.count != 2) {
        return CGPointMake(0, 0);
    }
    return CGPointMake(parts[0].floatValue, parts[1].floatValue);
}

- (NSString *)ba_sizeToStr:(CGSize)size {
    return [[NSString alloc] initWithFormat:@"%f,%f", size.width, size.height];
}

- (CGSize)ba_strToSize:(NSString *)str {
    if (![str isKindOfClass:[NSString class]]) {
        return CGSizeMake(0, 0);
    }
    NSArray <NSString *> *parts = [str componentsSeparatedByString:@","];
    if (parts.count != 2) {
        return CGSizeMake(0, 0);
    }
    return CGSizeMake(parts[0].floatValue, parts[1].floatValue);
}

- (NSString *)ba_rangeToStr:(NSRange)range {
    return [[NSString alloc] initWithFormat:@"%ld,%ld", range.location, range.length];
}

- (NSRange)ba_strToRange:(NSString *)str {
    if (![str isKindOfClass:[NSString class]]) {
        return NSMakeRange(0, 0);
    }
    NSArray <NSString *> *parts = [str componentsSeparatedByString:@","];
    if (parts.count != 2) {
        return NSMakeRange(0, 0);
    }
    return NSMakeRange(parts[0].integerValue, parts[1].integerValue);
}

- (NSString *)ba_setSelNameFromGetSelName:(NSString *)getSelName {
    return [[NSString alloc] initWithFormat:@"set%@%@:", [getSelName substringToIndex:1].uppercaseString, [getSelName substringFromIndex:1]];
}

@end

@implementation NSArray (BAModel)

- (NSArray *)ba_desWithObjCls:(Class)cls {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if (!cls) {
        return result;
    }
    for (id item in self) {
        if (![item isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        id itemObj = [[cls alloc] ba_initWithDictionary:item];
        if (!itemObj) {
            continue;
        }
        [result addObject:itemObj];
    }
    return result;
}

- (instancetype)ba_initWithDesObjCls:(Class)cls jsonStr:(NSString *)jsonStr {
    if (jsonStr.length <= 0) {
        return [super init];
    }
    NSError *jsonErr = nil;
    id jsonObj = [NSJSONSerialization JSONObjectWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingFragmentsAllowed error:&jsonErr];
    if (![jsonObj isKindOfClass:[NSArray class]]) {
        return [super init];
    }
    NSArray *tmpObjs = [(NSArray *)jsonObj ba_desWithObjCls:cls];
    return [self initWithArray:tmpObjs];
}

@end
