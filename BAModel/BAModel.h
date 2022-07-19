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

- (instancetype)bam_initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)bam_toDictionary;

- (instancetype)bam_initWithJsonStr:(NSString *)jsonStr;
- (NSString *)bam_toJsonStr;

@end

@protocol BAModelProtocol <NSObject>

@optional
- (NSArray <NSString *> *)bam_ignoredProperties;
- (NSDictionary <NSString *, NSString *> *)bam_customPropertyNames;
- (NSDictionary <NSString *, Class> *)bam_containerPropertyGenericClass;

@end
