//
//  BAModel.m
//  BAModel
//
//  Created by BenArvin on 2019/4/11.
//  Copyright © 2019 BenArvin. All rights reserved.
//

#import "BAModel.h"
#import <objc/runtime.h>

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

@property (nonatomic) NSRegularExpression *objClassRegular;

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
        
        _objClassRegular = [NSRegularExpression regularExpressionWithPattern:@"^@\"(.)*\"$" options:0 error:nil];
    }
    return self;
}

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static BAModelHelper *_shared;
    dispatch_once(&onceToken, ^{
        _shared = [[BAModelHelper alloc] init];
    });
    return _shared;
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

- (NSString *)bam_toJsonStr {
    if ([self isKindOfClass:[BAModel class]]) {
        return [((BAModel *)self) toJsonStr];
    } else if ([self isKindOfClass:[NSArray class]] || [self isKindOfClass:[NSDictionary class]]) {
        id newObj = [self bam_toBaseObject];
        if (!newObj) {
            return nil;
        }
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:newObj options:0 error:&error];
        if (error || !jsonData) {
            return nil;
        }
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return nil;
}

// array, dic, string, data, number
- (id)bam_toBaseObject {
    if ([self isKindOfClass:[BAModel class]]) {
        return [((BAModel *)self) toDictionary];
    } else if ([self isKindOfClass:[NSArray class]]) {
        NSMutableArray *result = [[NSMutableArray alloc] init];
        for (id item in (NSArray *)self) {
            id newItem = [item bam_toBaseObject];
            if (newItem) {
                [result addObject:newItem];
            }
        }
        return result;
    } else if ([self isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
        NSEnumerator *enumerator = [((NSDictionary *)self) keyEnumerator];
        id key;
        while ((key = [enumerator nextObject])) {
            if (![key isKindOfClass:[NSString class]]) {
                continue;
            }
            id value = [((NSDictionary *)self) valueForKey:key];
            id newValue = [value bam_toBaseObject];
            if (newValue) {
                [result setObject:newValue forKey:key];
            }
        }
        return result;
    } else if ([self isKindOfClass:[NSNumber class]]) {
        return self;
    } else if ([self isKindOfClass:[NSData class]]) {
        return self;
    } else if ([self isKindOfClass:[NSString class]]) {
        return self;
    } else if ([self isKindOfClass:[NSDate class]]) {
        return [BAModelHelper dateToStr:(NSDate *)self];
    }
    return nil;
}

@end

@implementation BAModel

#pragma mark - public methods
- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        [self loadFromDic:dictionary];
    }
    return self;
}

- (NSDictionary *)toDictionary
{
    return [self codeObject:self];
}

- (instancetype)initWithJsonStr:(NSString *)jsonStr {
    self = [super init];
    if (self) {
        NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
        if (jsonData) {
            NSError *err;
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
            if (!err && dic) {
                [self loadFromDic:dic];
            }
        }
    }
    return self;
}

- (NSString *)toJsonStr {
    NSDictionary *dic = [self toDictionary];
    if (!dic) {
        return nil;
    }
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:&error];
    if (error || !jsonData) {
        return nil;
    }
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (NSArray <NSString *> *)ignoredProperties
{
    return nil;
}

- (NSDictionary *)customPropertyNames
{
    return nil;
}

- (NSDictionary <NSString *, Class> *)containerPropertyGenericClass {
    return nil;
}

#pragma mark - private method
- (void)loadFromDic:(NSDictionary *)dic {
    if (!dic) {
        return;
    }
    
    NSMutableDictionary *propertyInfos = [[NSMutableDictionary alloc] init];
    Class currentClass = [self class];
    while (1) {
        if (currentClass == [BAModel class]) {
            break;
        }
        unsigned int propertyCount;
        objc_property_t *propertyList = class_copyPropertyList(currentClass, &propertyCount);
        for (int i=0; i<propertyCount; i++) {
            objc_property_t propertyItem = propertyList[i];
            NSString *propertyNameString = [NSString stringWithUTF8String:property_getName(propertyItem)];
            NSString *propertyClassString = [self propertyClassStringFromPropertyAttributes:propertyItem];
            if (propertyNameString && propertyClassString) {
                [propertyInfos setObject:propertyClassString forKey:propertyNameString];
            }
        }
        currentClass = [currentClass superclass];
    }
    
    NSArray *ignoredProperties = [self ignoredProperties];
    NSDictionary *genericClasses = [self containerPropertyGenericClass];
    
    NSEnumerator *enumerator = [dic keyEnumerator];
    id key;
    while ((key = [enumerator nextObject])) {
        if (![key isKindOfClass:[NSString class]]) {
            continue;
        }
        NSString *propertyName = [self propertyNameFromKey:key];
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
                NSMutableArray *newValue = [[NSMutableArray alloc] init];
                for (id item in (NSArray *)value) {
                    if (genericClass && [genericClass isSubclassOfClass:[BAModel class]]) {
                        id newItem = [[genericClass alloc] init];
                        [(BAModel *)newItem loadFromDic:item];
                        [newValue addObject:newItem];
                    } else {
                        [newValue addObject:item];
                    }
                }
                [self setValue:newValue forKey:propertyName];
            } else if ([propertyClass isSubclassOfClass:[NSDictionary class]]) {
                Class genericClass = [genericClasses objectForKey:propertyName];
                if (!genericClass || ![genericClass isSubclassOfClass:[BAModel class]]) {
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
                    if (genericClass && [genericClass isSubclassOfClass:[BAModel class]]) {
                        id newItem = [[genericClass alloc] init];
                        [(BAModel *)newItem loadFromDic:oldItem];
                        [newValue setValue:innerKey forKey:newItem];
                    } else {
                        [newValue setValue:innerKey forKey:oldItem];
                    }
                }
                [self setValue:newValue forKey:propertyName];
            } else if ([propertyClass isSubclassOfClass:[BAModel class]]) {
                id newVlaue = [[propertyClass alloc] init];
                [(BAModel *)newVlaue loadFromDic:value];
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
                [self setValue:[NSValue valueWithCGRect:CGRectFromString(value)] forKey:propertyName];
            } else if ([propertyClassName isEqualToString:[BAModelHelper shared].pointClassStr]) {
                [self setValue:[NSValue valueWithCGPoint:CGPointFromString(value)] forKey:propertyName];
            } else if ([propertyClassName isEqualToString:[BAModelHelper shared].sizeClassStr]) {
                [self setValue:[NSValue valueWithCGSize:CGSizeFromString(value)] forKey:propertyName];
            } else if ([propertyClassName isEqualToString:[BAModelHelper shared].rangeClassStr]) {
                [self setValue:[NSValue valueWithRange:NSRangeFromString(value)] forKey:propertyName];
            }
        }
    }
}

- (NSString *)propertyNameFromKey:(NSString *)key
{
    if (!key || key.length == 0) {
        return nil;
    }
    NSDictionary *nameKeyDictionary = [self customPropertyNames];
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

- (NSString *)keyFromPropertyName:(NSString *)propertyName
{
    if (!propertyName || propertyName.length == 0) {
        return nil;
    }
    NSDictionary *nameKeyDictionary = [self customPropertyNames];
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

- (NSString *)propertyClassStringFromPropertyAttributes:(objc_property_t)property
{
    objc_property_attribute_t *list = property_copyAttributeList(property, nil);
    return [NSString stringWithUTF8String:list[0].value];
}

- (id)decodeObject:(id)object withClass:(Class)objectClass innerClass:(Class)innerClass
{
    if ([objectClass isSubclassOfClass:[BAModel class]]) {
        return [[objectClass alloc] initWithDictionary:object];
    } else if ([objectClass isSubclassOfClass:[NSArray class]]) {
        if (innerClass) {
            NSMutableArray *result = nil;
            for (id arraryItem in (NSArray *)object) {
                if (!result) {
                    result = [[NSMutableArray alloc] init];
                }
                [result addObject:[[innerClass alloc] initWithDictionary:arraryItem]];
            }
            return result;
        } else {
            return object;
        }
    } else if ([objectClass isSubclassOfClass:[NSDictionary class]]) {
        return object;
    } else {
        return object;
    }
}

- (id)codeObject:(id)object
{
    if ([object isKindOfClass:[NSString class]]
        || [object isKindOfClass:[NSData class]]
        || [object isKindOfClass:[NSNumber class]]) {
        return object;
    } else if ([object isKindOfClass:[NSDate class]]) {
        return [BAModelHelper dateToStr:(NSDate *)object];
    } else if ([object isKindOfClass:[NSArray class]]) {
        NSMutableArray *result = nil;
        for (id arrayItem in (NSArray *)object) {
            if (!result) {
                result = [[NSMutableArray alloc] init];
            }
            id convertedItem = [self codeObject:arrayItem];
            if (convertedItem) {
                [result addObject:convertedItem];
            }
        }
        return result;
    } else if ([object isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *result = nil;
        NSDictionary *dictionary = (NSDictionary *)object;
        for (id keyItem in [dictionary allKeys]) {
            id valueItem = [dictionary objectForKey:keyItem];
            id convertedKey = [self codeObject:keyItem];
            id convertedValue = [self codeObject:valueItem];
            if (!convertedKey || !convertedValue) {
                continue;
            }
            if (!result) {
                result = [[NSMutableDictionary alloc] init];
            }
            [result setObject:convertedValue forKey:convertedKey];
        }
        return result;
    } else if ([object isKindOfClass:[BAModel class]]) {
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
        NSArray *ignoredProperties = [self ignoredProperties];
        Class currentClass = [object class];
        while (1) {
            if (currentClass == [BAModel class]) {
                break;
            }
            
            unsigned int propertyCount;
            objc_property_t *propertyList = class_copyPropertyList(currentClass, &propertyCount);
            for (int i=0; i<propertyCount; i++) {
                objc_property_t propertyItem = propertyList[i];
                NSString *propertyNameString = [NSString stringWithUTF8String:property_getName(propertyItem)];
                if ([ignoredProperties containsObject:propertyNameString]) {
                    continue;
                }
                NSString *keyString = [self keyFromPropertyName:propertyNameString];
                if (!keyString || keyString.length == 0) {
                    continue;
                }
                NSString *propertyClassString = [self propertyClassStringFromPropertyAttributes:propertyItem];
                if (!propertyClassString || propertyClassString.length == 0) {
                    continue;
                }
                id propertyValue = [object valueForKey:propertyNameString];
                if ([BAModelHelper isObjectClass:propertyClassString]) {
                    setDicObjectBlock([self codeObject:propertyValue], keyString);
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
                        CGRect rectValue = [(NSValue *)propertyValue CGRectValue];
                        setDicObjectBlock(NSStringFromCGRect(rectValue), keyString);
                    } else if ([propertyClassString isEqualToString:[BAModelHelper shared].pointClassStr]) {
                        CGPoint pointValue = [(NSValue *)propertyValue CGPointValue];
                        setDicObjectBlock(NSStringFromCGPoint(pointValue), keyString);
                    } else if ([propertyClassString isEqualToString:[BAModelHelper shared].sizeClassStr]) {
                        CGSize sizeValue = [(NSValue *)propertyValue CGSizeValue];
                        setDicObjectBlock(NSStringFromCGSize(sizeValue), keyString);
                    } else if ([propertyClassString isEqualToString:[BAModelHelper shared].rangeClassStr]) {
                        NSRange rangeValue = [(NSValue *)propertyValue rangeValue];
                        setDicObjectBlock(NSStringFromRange(rangeValue), keyString);
                    }
                }
            }
            
            currentClass = [currentClass superclass];
        }
        return result;
    } else {
        return nil;
    }
}

@end
