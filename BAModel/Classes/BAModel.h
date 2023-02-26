//
//  BAModel.h
//  BAModel
//
//  Created by BenArvin on 2019/4/11.
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Supported property classes:
/// int, unsignedInt, NSInteger, NSUInteger, float, double
/// CGRect, CGPoint, CGSize, NSRange
/// NSString, NSData, NSDate, NSNumber
/// NSArray, NSDictionary
@interface NSObject (BAModel)

+ (instancetype)ba_newWithDictionary:(NSDictionary *)dictionary;
- (instancetype)ba_initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)ba_toDictionary;

+ (instancetype)ba_newWithJsonStr:(NSString *)jsonStr;
- (instancetype)ba_initWithJsonStr:(NSString *)jsonStr;
- (NSString *)ba_toJsonStr;

@end

@interface NSArray (BAModel)

- (NSArray *)ba_desWithObjCls:(Class)cls;
- (instancetype)ba_initWithDesObjCls:(Class)cls jsonStr:(NSString *)jsonStr;

@end

@protocol BAModelProtocol <NSObject>

@optional
- (NSArray <NSString *> *)ba_ignoredProperties;
- (NSDictionary <NSString *, NSString *> *)ba_customPropertyNames;
- (NSDictionary <NSString *, NSString *> *)ba_customPropertyCls;
- (NSDictionary <NSString *, Class> *)ba_containerPropertyGenericClass;

@end
