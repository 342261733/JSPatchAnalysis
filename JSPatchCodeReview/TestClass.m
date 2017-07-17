//
//  TestClass.m
//  JSPatchCodeReview
//
//  Created by Semyon on 2017/4/25.
//  Copyright © 2017年 Semyon. All rights reserved.
//

#import "TestClass.h"

@implementation TestClass

- (void)setGirlFriend:(NSObject *)girlFriend {
    _girlFriend = girlFriend;
    NSLog(@"girlfrend");
}

- (void)setAa:(int)aa {
    _aa = aa;
}

- (void)runTest {
    NSLog(@"run test");
}

//- (void)runTestNew {
//    NSLog(@"run Test New");
//}

void runTestNewImp() {
    NSLog(@"runTestNewImp");
}

- (void)testArgumentChanges {
    NSLog(@"testArgumentChanges in test class");
}

@end
