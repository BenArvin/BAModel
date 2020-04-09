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
@end

@implementation BAModelHelper

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
    if (!classStr || classStr.length <= 4) {
        return NO;
    }
    NSInteger resultsCount = [[self objClassRegular] numberOfMatchesInString:classStr options:0 range:NSMakeRange(0, classStr.length)];
    return (resultsCount == 1);
}

+ (Class)getObjectClass:(NSString *)classStr {
    if (![self isObjectClass:classStr]) {
        return nil;
    }
    NSString *newClassStr = [classStr substringWithRange:NSMakeRange(3, classStr.length - 4)];
    return NSClassFromString(newClassStr);
}

+ (NSString *)rectClassStr {
    return @"T{CGRect={CGPoint=dd}{CGSize=dd}}";
}

+ (NSString *)pointClassStr {
    return @"T{CGPoint=dd}";
}

+ (NSString *)sizeClassStr {
    return @"T{CGSize=dd}";
}

+ (NSString *)rangeClassStr {
    return @"T{_NSRange=QQ}";
}

+ (NSString *)boolClassStr
{
    static NSString *classNameBOOL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classNameBOOL = [NSString stringWithFormat:@"T%c", _C_BOOL];
    });
    return classNameBOOL;
}

+ (NSString *)intClassStr
{
    static NSString *classNameInt;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classNameInt = [NSString stringWithFormat:@"T%c", _C_INT];
    });
    return classNameInt;
}

+ (NSString *)unsignedIntClassStr
{
    static NSString *classNameUnsignedInt;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classNameUnsignedInt = [NSString stringWithFormat:@"T%c", _C_UINT];
    });
    return classNameUnsignedInt;
}

+ (NSString *)NSIntegerClassStr
{
    static NSString *classNameNSInteger;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classNameNSInteger = [NSString stringWithFormat:@"T%c", _C_LNG_LNG];
    });
    return classNameNSInteger;
}

+ (NSString *)NSUIntegerClassStr
{
    static NSString *classNameNSUInteger;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classNameNSUInteger = [NSString stringWithFormat:@"T%c", _C_ULNG_LNG];
    });
    return classNameNSUInteger;
}

+ (NSString *)floatClassStr
{
    static NSString *classNameFloat;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classNameFloat = [NSString stringWithFormat:@"T%c", _C_FLT];
    });
    return classNameFloat;
}

+ (NSString *)doubleClassStr
{
    static NSString *classNameDouble;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classNameDouble = [NSString stringWithFormat:@"T%c", _C_DBL];
    });
    return classNameDouble;
}

#pragma mark - private methods
+ (NSRegularExpression *)objClassRegular {
    static dispatch_once_t onceToken;
    static NSRegularExpression *_objClassRegular;
    dispatch_once(&onceToken, ^{
        _objClassRegular = [NSRegularExpression regularExpressionWithPattern:@"^T@\"(.)*\"$" options:0 error:nil];
    });
    return _objClassRegular;
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
            NSString *propertyClassString = [self propertyClassStringFromPropertyAttributes:property_getAttributes(propertyItem)];
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
            if ([propertyClassName isEqualToString:[BAModelHelper boolClassStr]]
                || [propertyClassName isEqualToString:[BAModelHelper intClassStr]]
                || [propertyClassName isEqualToString:[BAModelHelper unsignedIntClassStr]]
                || [propertyClassName isEqualToString:[BAModelHelper NSIntegerClassStr]]
                || [propertyClassName isEqualToString:[BAModelHelper NSUIntegerClassStr]]) {
                [self setValue:@(((NSString *)value).intValue) forKey:propertyName];
            } else if ([propertyClassName isEqualToString:[BAModelHelper floatClassStr]]) {
                [self setValue:@(((NSString *)value).floatValue) forKey:propertyName];
            } else if ([propertyClassName isEqualToString:[BAModelHelper doubleClassStr]]) {
                [self setValue:@(((NSString *)value).doubleValue) forKey:propertyName];
            } else if ([propertyClassName isEqualToString:[BAModelHelper rectClassStr]]) {
                [self setValue:[NSValue valueWithCGRect:CGRectFromString(value)] forKey:propertyName];
            } else if ([propertyClassName isEqualToString:[BAModelHelper pointClassStr]]) {
                [self setValue:[NSValue valueWithCGPoint:CGPointFromString(value)] forKey:propertyName];
            } else if ([propertyClassName isEqualToString:[BAModelHelper sizeClassStr]]) {
                [self setValue:[NSValue valueWithCGSize:CGSizeFromString(value)] forKey:propertyName];
            } else if ([propertyClassName isEqualToString:[BAModelHelper rangeClassStr]]) {
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

- (NSString *)propertyClassStringFromPropertyAttributes:(const char *)propertyAttributes
{
    NSString *propertyAttributesString = [NSString stringWithUTF8String:propertyAttributes];
    if (!propertyAttributesString || propertyAttributesString.length == 0) {
        return nil;
    }
    return [propertyAttributesString componentsSeparatedByString:@","].firstObject;
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
                NSString *propertyClassString = [self propertyClassStringFromPropertyAttributes:property_getAttributes(propertyItem)];
                if (!propertyClassString || propertyClassString.length == 0) {
                    continue;
                }
                id propertyValue = [object valueForKey:propertyNameString];
                if ([BAModelHelper isObjectClass:propertyClassString]) {
                    setDicObjectBlock([self codeObject:propertyValue], keyString);
                } else {
                    if ([propertyClassString isEqualToString:[BAModelHelper boolClassStr]]
                        || [propertyClassString isEqualToString:[BAModelHelper intClassStr]]
                        || [propertyClassString isEqualToString:[BAModelHelper unsignedIntClassStr]]
                        || [propertyClassString isEqualToString:[BAModelHelper NSIntegerClassStr]]
                        || [propertyClassString isEqualToString:[BAModelHelper NSUIntegerClassStr]]) {
                        setDicObjectBlock(propertyValue, keyString);
                    } else if ([propertyClassString isEqualToString:[BAModelHelper floatClassStr]]) {
                        setDicObjectBlock([NSString stringWithFormat:@"%.6f", ((NSNumber *)propertyValue).floatValue], keyString);
                    }  else if ([propertyClassString isEqualToString:[BAModelHelper doubleClassStr]]) {
                        setDicObjectBlock([NSString stringWithFormat:@"%.14f", ((NSNumber *)propertyValue).doubleValue], keyString);
                    } else if ([propertyClassString isEqualToString:[BAModelHelper rectClassStr]]) {
                        CGRect rectValue = [(NSValue *)propertyValue CGRectValue];
                        setDicObjectBlock(NSStringFromCGRect(rectValue), keyString);
                    } else if ([propertyClassString isEqualToString:[BAModelHelper pointClassStr]]) {
                        CGPoint pointValue = [(NSValue *)propertyValue CGPointValue];
                        setDicObjectBlock(NSStringFromCGPoint(pointValue), keyString);
                    } else if ([propertyClassString isEqualToString:[BAModelHelper sizeClassStr]]) {
                        CGSize sizeValue = [(NSValue *)propertyValue CGSizeValue];
                        setDicObjectBlock(NSStringFromCGSize(sizeValue), keyString);
                    } else if ([propertyClassString isEqualToString:[BAModelHelper rangeClassStr]]) {
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
