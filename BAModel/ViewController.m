//
//  ViewController.m
//  BAModel
//
//  Created by BenArvin on 2019/4/11.
//  Copyright © 2019 BenArvin. All rights reserved.
//

#import "ViewController.h"
#import "BAModel.h"

@interface BATestModel0 : BAModel

@property (nonatomic) NSString *string;

@end

@implementation BATestModel0

@end

@interface BATestModel : BAModel

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

@interface BATestFatherModel : BAModel

@property (nonatomic) NSString *fatherStr;
@property (nonatomic) NSString *fatherIgStr;

@end

@interface BATestSonModel : BATestFatherModel

@property (nonatomic) NSString *sonStr;

@end

@implementation BATestFatherModel

- (NSArray *)ignoredProperties {
    return @[@"fatherIgStr"];
}

@end

@implementation BATestSonModel
@end

@implementation BATestModel

//- (NSArray *)ignoredProperties {
//    return @[@"key1"];
//}

- (NSDictionary <NSString *, Class> *)containerPropertyGenericClass {
    return @{@"inners": [BATestModel0 class]};
}

@end

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    BATestModel0 *inner = [[BATestModel0 alloc] init];
//    inner.string = @"innerStr";
//
//    BATestModel0 *inner2 = [[BATestModel0 alloc] init];
//    inner2.string = @"innerStr";
//
//    BATestModel *test0 = [[BATestModel alloc] init];
//    test0.inner = inner;
//    test0.strArray = @[@"str1", @"str2"];
//    test0.inners = @[inner2];
//    test0.boolValue = YES;
//    test0.str = @"stringTest";
//    test0.intValue = 919;
//    test0.rect = CGRectMake(0, 0, 12.3, 34);
//    test0.point = CGPointMake(1, -9.234578);
//    test0.floatValue = 999.123456789012345678901234567890123456789;
//    test0.doubleValue = 999.123456789012345678901234567890123456789;
//    test0.rangeValue = NSMakeRange(12, 34);
//    test0.date = [NSDate date];
//
//    NSDictionary *objDic = [test0 toDictionary];
//
//    BATestModel *test1 = [[BATestModel alloc] initWithDictionary:objDic];
//
//    NSString *json = [test1 toJsonStr];
//
//    BATestModel *test2 = [[BATestModel alloc] initWithJsonStr:json];
//
//    NSArray *array = @[test0];
//    NSDictionary *dic = @{@"testobj": test0};
    
    BATestSonModel *model = [[BATestSonModel alloc] init];
    model.fatherStr = @"testF";
    model.fatherIgStr = @"testIgF";
    model.sonStr = @"testS";
     
    NSDictionary *objc = [model toDictionary];
    
    BATestSonModel *newModel = [[BATestSonModel alloc] initWithDictionary:objc];
    
    NSLog(@"");
}


@end
