//
//  BAModel.h
//  BAModel
//
//  Created by BenArvin on 2019/4/11.
//  Copyright © 2019 BenArvin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BAModel : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)toDictionary;

- (NSSet *)ignoredPropertyName;
- (NSDictionary *)specialPropertyName;
- (NSDictionary *)containedObjectClass;

@end
