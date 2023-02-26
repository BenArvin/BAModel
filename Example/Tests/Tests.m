//
//  BAModelTests.m
//  BAModelTests
//
//  Created by arvinnie on 02/26/2023.
//  Copyright (c) 2023 arvinnie. All rights reserved.
//

#import <BAModel/BAModel.h>

@import XCTest;

@interface BATestModel0 : NSObject

@property (nonatomic) NSString *string;

@end

@implementation BATestModel0

@end

@interface BATestModel : NSObject

@property (nonatomic) NSArray <BATestModel0 *> *inners;
@property (nonatomic) NSArray <NSString *> *strArray;
@property (nonatomic) BATestModel0 *inner;
@property (nonatomic) BOOL boolValue;
@property (nonatomic) NSString *str;
@property (nonatomic) NSInteger intValue;
@property (nonatomic) CGRect rect;
@property (nonatomic) CGPoint point;
@property (nonatomic) NSDate *date;
@property (nonatomic) float floatValue;
@property (nonatomic) double doubleValue;
@property (nonatomic) NSRange rangeValue;

@end

@interface BATestFatherModel : NSObject

@property (nonatomic) NSString *fatherStr;
@property (nonatomic) NSString *fatherIgStr;

@end

@interface BATestSonModel : BATestFatherModel

@property (nonatomic) NSString *sonStr;

@end

@implementation BATestFatherModel

- (NSArray *)bam_ignoredProperties {
    return @[@"fatherIgStr"];
}

@end

@implementation BATestSonModel
@end

@implementation BATestModel

- (NSArray *)bam_ignoredProperties {
    return @[@"key1"];
}

- (NSDictionary <NSString *, Class> *)bam_containerPropertyGenericClass {
    return @{@"inners": [BATestModel0 class]};
}

@end

@interface TestCusProCls : NSObject

@end

@implementation TestCusProCls

@end

@interface Tests : XCTestCase

@end

@implementation Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)test1 {
    BATestModel0 *inner = [[BATestModel0 alloc] init];
    inner.string = @"innerStr";

    BATestModel0 *inner2 = [[BATestModel0 alloc] init];
    inner2.string = @"innerStr";

    BATestModel *test0 = [[BATestModel alloc] init];
    test0.inner = inner;
    test0.strArray = @[@"str1", @"str2"];
    test0.inners = @[inner2];
    test0.boolValue = YES;
    test0.str = @"stringTest";
    test0.intValue = 919;
    test0.rect = CGRectMake(0, 0, 12.3, 34);
    test0.point = CGPointMake(1, -9.234578);
    test0.floatValue = 999.123456789012345678901234567890123456789;
    test0.doubleValue = 999.123456789012345678901234567890123456789;
    test0.rangeValue = NSMakeRange(12, 34);
    test0.date = [NSDate date];

    NSDictionary *objDic = [test0 ba_toDictionary];

    BATestModel *test1 = [[BATestModel alloc] ba_initWithDictionary:objDic];
    
    NSLog(@"");

    NSString *json = [test1 ba_toJsonStr];

    BATestModel *test2 = [[BATestModel alloc] ba_initWithJsonStr:json];

    NSString *json2 = [@[test0] ba_toJsonStr];
    NSString *json3 = [@{@"testobj": test0} ba_toJsonStr];

    BATestSonModel *model = [[BATestSonModel alloc] init];
    model.fatherStr = @"testF";
    model.fatherIgStr = @"testIgF";
    model.sonStr = @"testS";

    NSDictionary *objc = [model ba_toDictionary];

    BATestSonModel *newModel = [[BATestSonModel alloc] ba_initWithDictionary:objc];
}

- (void)test2 {
    NSString *json = @"";
}

@end

