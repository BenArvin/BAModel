//
//  BAModel.m
//  BAModel
//
//  Created by BenArvin on 2019/4/11.
//  Copyright © 2019 BenArvin. All rights reserved.
//

#import "BAModel.h"
#import <objc/runtime.h>

@implementation BAModel

#pragma mark - public methods
- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        NSEnumerator *enumerator = [dictionary keyEnumerator];
        id key;
        while ((key = [enumerator nextObject])) {
            if (![key isKindOfClass:[NSString class]]) {
                continue;
            }
            NSString *propertyName = [self propertyNameFromKey:key];
            if (!key || !propertyName) {
                continue;
            }
            id valueItem = [dictionary valueForKey:key];
            if (![self respondsToSelector:NSSelectorFromString(propertyName)]) {
                continue;//property not exist
            }
            NSString *propertyClassString = [self propertyClassStringFromPropertyAttributes:property_getAttributes(class_getProperty([self class], propertyName.UTF8String))];
            Class propertyClass = [self propertyClassFromPropertyClassString:propertyClassString];
            if (propertyClass) {
                [self setValue:[self decodeObject:valueItem withClass:propertyClass innerClass:[self propertyGenericsWithPropertyName:propertyName]] forKey:propertyName];
            } else {
                [self setValue:[self decodeObject:valueItem withClass:nil innerClass:nil] forKey:propertyName];
            }
        }
    }
    return self;
}

- (NSDictionary *)toDictionary
{
    return [self codeObject:self];
}

- (NSSet *)ignoredPropertyName
{
    return nil;
}

- (NSDictionary *)specialPropertyName
{
    return nil;
}

- (NSDictionary *)containedObjectClass
{
    return nil;
}

#pragma mark - private method
- (NSString *)propertyNameFromKey:(NSString *)key
{
    if (!key || key.length == 0) {
        return nil;
    }
    NSDictionary *nameKeyDictionary = [self specialPropertyName];
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
    NSDictionary *nameKeyDictionary = [self specialPropertyName];
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

- (Class)propertyGenericsWithPropertyName:(NSString *)propertyName
{
    if (!propertyName || propertyName.length == 0) {
        return nil;
    }
        NSDictionary *genericsDictionary = [self containedObjectClass];
    if (!genericsDictionary) {
        return nil;
    }
    return [genericsDictionary objectForKey:propertyName];
}

- (NSString *)propertyClassStringFromPropertyAttributes:(const char *)propertyAttributes
{
    NSString *propertyAttributesString = [NSString stringWithUTF8String:propertyAttributes];
    if (!propertyAttributesString || propertyAttributesString.length == 0) {
        return nil;
    }
    return [propertyAttributesString componentsSeparatedByString:@","].firstObject;
}

- (Class)propertyClassFromPropertyClassString:(NSString *)propertyClassString
{
    if (!propertyClassString || propertyClassString.length <= 1) {
        return nil;
    }
    if ([propertyClassString rangeOfString:@"T@\""].location != NSNotFound) {
        return NSClassFromString([propertyClassString substringWithRange:NSMakeRange(3, propertyClassString.length - 4)]);
    } else {
        return nil;
    }
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
        || [object isKindOfClass:[NSMutableString class]]
        || [object isKindOfClass:[NSData class]]
        || [object isKindOfClass:[NSMutableData class]]
        || [object isKindOfClass:[NSNumber class]]) {
        return object;
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
        
        unsigned int propertyCount;
        objc_property_t *propertyList = class_copyPropertyList([object class], &propertyCount);
        for (int i=0; i<propertyCount; i++) {
            objc_property_t propertyItem = propertyList[i];
            NSString *propertyNameString = [NSString stringWithUTF8String:property_getName(propertyItem)];
            NSString *keyString = [self keyFromPropertyName:propertyNameString];
            NSString *propertyClassString = [self propertyClassStringFromPropertyAttributes:property_getAttributes(propertyItem)];
            Class propertyClass = [self propertyClassFromPropertyClassString:propertyClassString];
            id propertyValue = [object valueForKey:propertyNameString];
            if (propertyClass) {
                setDicObjectBlock([self codeObject:propertyValue], keyString);
            } else {
                if ([propertyClassString isEqualToString:self.classNameBOOL]
                    || [propertyClassString isEqualToString:self.classNameInt]
                    || [propertyClassString isEqualToString:self.classNameUnsignedInt]
                    || [propertyClassString isEqualToString:self.classNameNSInteger]
                    || [propertyClassString isEqualToString:self.classNameNSUInteger]
                    || [propertyClassString isEqualToString:self.classNameFloat]
                    || [propertyClassString isEqualToString:self.classNameDouble]) {
                    setDicObjectBlock(propertyValue, keyString);
                }
            }
        }
        return result;
    } else {
        return nil;
    }
}

- (NSString *)classNameBOOL
{
    static NSString *classNameBOOL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classNameBOOL = [NSString stringWithFormat:@"T%c", _C_BOOL];
    });
    return classNameBOOL;
}

- (NSString *)classNameInt
{
    static NSString *classNameInt;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classNameInt = [NSString stringWithFormat:@"T%c", _C_INT];
    });
    return classNameInt;
}

- (NSString *)classNameUnsignedInt
{
    static NSString *classNameUnsignedInt;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classNameUnsignedInt = [NSString stringWithFormat:@"T%c", _C_UINT];
    });
    return classNameUnsignedInt;
}

- (NSString *)classNameNSInteger
{
    static NSString *classNameNSInteger;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classNameNSInteger = [NSString stringWithFormat:@"T%c", _C_LNG_LNG];
    });
    return classNameNSInteger;
}

- (NSString *)classNameNSUInteger
{
    static NSString *classNameNSUInteger;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classNameNSUInteger = [NSString stringWithFormat:@"T%c", _C_ULNG_LNG];
    });
    return classNameNSUInteger;
}

- (NSString *)classNameFloat
{
    static NSString *classNameFloat;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classNameFloat = [NSString stringWithFormat:@"T%c", _C_FLT];
    });
    return classNameFloat;
}

- (NSString *)classNameDouble
{
    static NSString *classNameDouble;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classNameDouble = [NSString stringWithFormat:@"T%c", _C_DBL];
    });
    return classNameDouble;
}

@end
