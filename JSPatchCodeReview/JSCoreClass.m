//
//  JSCoreClass.m
//  JSPatchCodeReview
//
//  Created by Semyon on 2017/4/27.
//  Copyright © 2017年 Semyon. All rights reserved.
//

#import "JSCoreClass.h"
#import <JavaScriptCore/JavaScriptCore.h>

@implementation JSCoreClass

+ (void)ocInvokeJs {
    JSContext *context = [[JSContext alloc] init];
    context[@"jsFunc"] = ^(JSValue *key, JSValue *value){
        NSLog(@"key %@ value %@", key, value);
    };
    
    // **** 两种OC调用JS的方法：
    [context evaluateScript:@"jsFunc('hello', 'JS')"];
    [context[@"jsFunc"] callWithArguments:@[@"hello", @"JS call"]];
    
    context[@"call"] = ^(NSString *msg){
        NSLog(@"hello %@", msg);
    };
    [context evaluateScript:@"call('js')"];
    
    [context evaluateScript:@"function funcAdd(a,b) {return a+b}"];
    JSValue *retunVaule = [context[@"funcAdd"] callWithArguments:@[@1, @3]];
    NSLog(@"result is %@", retunVaule.toString);
    
    // JSManagedValue 用于管理JSValue，JS中的对象都是强引用，用JSManagedValue保存JSValue来避免循环引用，避免内存泄露
    JSManagedValue *managedValue = [JSManagedValue managedValueWithValue:retunVaule];
    JSValue *returnValue = managedValue.value;
    NSLog(@"return value in manage is %@", returnValue.toString);
}


@end
