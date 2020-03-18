//
//  BAModel.h
//  BAModel
//
//  Created by BenArvin on 2019/4/11.
//  Copyright © 2019 BenArvin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSObject (BAModel)

- (NSString *)bam_toJsonStr;

@end

/// Supported property classes:
/// int, unsignedInt, NSInteger, NSUInteger, float, double
/// CGRect, CGPoint, CGSize, NSRange
/// NSString, NSData, NSDate, NSNumber
/// NSArray, NSDictionary
@interface BAModel : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)toDictionary;

- (instancetype)initWithJsonStr:(NSString *)jsonStr;
- (NSString *)toJsonStr;

- (NSArray <NSString *> *)ignoredProperties;
- (NSDictionary <NSString *, NSString *> *)customPropertyNames;
- (NSDictionary <NSString *, Class> *)containerPropertyGenericClass;

@end
