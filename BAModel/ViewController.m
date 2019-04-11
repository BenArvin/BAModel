//
//  ViewController.m
//  BAModel
//
//  Created by BenArvin on 2019/4/11.
//  Copyright © 2019 BenArvin. All rights reserved.
//

#import "ViewController.h"
#import "BAModel.h"

@interface BATestModel : BAModel

@property (nonatomic) BOOL key1;
@property (nonatomic) NSString *key2;
@property (nonatomic) NSInteger key3;

@end

@implementation BATestModel

@end

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    BATestModel *test = [[BATestModel alloc] initWithDictionary: @{@"key1": @(1), @"key2": @"value2", @"key3": @"1"}];
    NSLog(@"");
}


@end
