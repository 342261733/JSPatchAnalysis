//
//  ViewController.m
//  JSPatchCodeReview
//
//  Created by Semyon on 2017/4/25.
//  Copyright © 2017年 Semyon. All rights reserved.
//

#import "ViewController.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <objc/runtime.h>
#import "TestClass.h"
#import "JSCoreClass.h"
#import "JPEngine.h"

@interface ViewController () {
    TestClass *testClass;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [self testJSCore];
//    [self testRuntimeMethod];
//    [self testIvarLayout];
//    [self testObjSend];
//    [self testKVO];
//    [self testVarableInStack];
}

- (void)testVarableInStack {
    int vaI = 10;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self say:&vaI];
    });
    NSLog(@"%d %p", vaI, vaI);
    NSObject *obj = [[NSObject alloc] init];
    int *val2 = &vaI;
    NSMutableArray *arrM = [[NSMutableArray alloc] initWithObjects:@"2", nil];
    NSLog(@"arrM %@ %p", arrM, arrM);
    NSLog(@"arrM %p", &arrM);
    void *bb = [self pointChange:&arrM];
    ^(void) {
        *val2 = 133;
        NSLog(@"val2 %d", *val2);
        [arrM addObject:@"3"];
        NSLog(@"arrM %@", arrM);
//        NSMutableArray *arrOri = (NSMutableArray *)(&bb);
        
    }();
}

- (void)say:(int *)s {
    NSLog(@"%p", s);
    *s = 11;
    int b = *s;
    NSLog(@"b is %d", b);
}

- (NSMutableArray **)pointChange:(NSMutableArray **)arrM {
    *arrM = @[@3];
    return arrM;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)testKVO {
    testClass = [[TestClass alloc] init];
    [testClass addObserver:self forKeyPath:@"aa" options:NSKeyValueObservingOptionNew context:nil];
    //    testClass.girlFriend = @"he";
    //    testClass.girlFriend = @"hh";
    testClass.aa = 3;
    testClass.aa = 4;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"keyPath %@", keyPath);
    NSLog(@"change %@", change);
}

- (void)testJSCore {

    [JSCoreClass ocInvokeJs];
}

- (void)testRuntimeMethod {
    Class cls = NSClassFromString(@"TestClass");
    SEL selector = @selector(runTest);
    Method method = class_getInstanceMethod(cls, selector);
    IMP imp = method_getImplementation(method);
    NSLog(@"imp %p", imp);
    char *typeEncoding = (char *)method_getTypeEncoding(method);
    NSLog(@"typeEncoding %s", typeEncoding);
    class_addMethod(cls, @selector(runTestNew), imp, typeEncoding);
    class_replaceMethod(cls, selector, runTestImp, typeEncoding);
    
    TestClass *tcls = [[TestClass alloc] init];
    [tcls performSelector:@selector(runTest)]; // 实际调用 runTestImp
    [tcls performSelector:@selector(runTestNew)]; // 实际调用 runTest,如果TestClass中实现了runTestNew，那么会调用runTestNew。如果么有实现，那么会调用runTest。猜测是因为：runtime是后添加的方法，导致先取得数组前面的方法（也就是实例方法）实现。
}

- (void)testIvarLayout {
    Class class = objc_allocateClassPair(NSObject.class, "Sark", 0);
    class_addIvar(class, "_gayFriend", sizeof(id), log2(sizeof(id)), @encode(id));
    class_addIvar(class, "_girlFriend", sizeof(id), log2(sizeof(id)), @encode(id));
    class_addIvar(class, "_company", sizeof(id), log2(sizeof(id)), @encode(id));
    class_setIvarLayout(class, (const uint8_t *)"\x01\x12"); // <--- new
    class_setWeakIvarLayout(class, (const uint8_t *)"\x11\x10"); // <--- new
    objc_registerClassPair(class);
    
    id sark = [class new];
    Ivar weakIvar = class_getInstanceVariable(class, "_girlFriend");
    Ivar strongIvar = class_getInstanceVariable(class, "_gayFriend");
    {
        id girl = [NSObject new];
        id boy = [NSObject new];
        object_setIvar(sark, weakIvar, girl);
        object_setIvar(sark, strongIvar, boy);

        id weakObj = object_getIvar(sark, weakIvar);
        id strongObj = object_getIvar(sark, strongIvar);
        NSLog(@"weakIvar %@, strongIvar %@", object_getIvar(sark, weakIvar), object_getIvar(sark, strongIvar));
    } // ARC 在这里会释放大括号内的 girl，boy
    // 输出：weakIvar 为 nil，strongIvar 有值

//    NSLog(@"weakIvar %@, strongIvar %@", object_getIvar(sark, weakIvar), object_getIvar(sark, strongIvar));
}

void runTestImp() {
    NSLog(@"runTestImp ");
}

- (void)testArgumentChange {
    NSLog(@"testArgumentChange ");
}

+ (void)testClassInvoke {
    NSLog(@"testClassInvoke");
}

- (void)testObjSend {
    
//    SEL tSelector = @selector(testClassInvokes);
//    NSMethodSignature *signature = [[self class] methodSignatureForSelector:tSelector];
//    NSInvocation *invokation = [NSInvocation invocationWithMethodSignature:signature];
//    [invokation setTarget:[self class]];
//    [invokation setSelector:tSelector];
//    [invokation invoke];
    
    SEL hselector = @selector(testArgumentChanges);
//    [self performSelector:hselector];
    
    NSMethodSignature *signature = [self methodSignatureForSelector:hselector];
    NSInvocation *invokation = [NSInvocation invocationWithMethodSignature:signature];
    [invokation setTarget:self];
    [invokation setSelector:hselector];
    [invokation invoke];
}

#pragma mark - 拦截调用

+ (BOOL)resolveClassMethod:(SEL)sel {
    NSLog(@"resolveClassMethod %@", NSStringFromSelector(sel));
    return YES;
}

+ (BOOL)resolveInstanceMethod:(SEL)sel {
//    if ([NSStringFromSelector(sel) isEqualToString:@"HHHH"]) {
//        class_addMethod(self, sel, hhhhImp, "vv");
//    }
    NSLog(@"resolveInstanceMethod %@", NSStringFromSelector(sel));
    return YES;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    NSLog(@"forwardInvocation %@", anInvocation);
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    NSLog(@"forwardingTargetForSelector %@", NSStringFromSelector(aSelector));
    if ([NSStringFromSelector(aSelector) isEqualToString:@"testArgumentChanges"]) {
        return self;
    }
    return nil;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSLog(@"methodSignatureForSelector %@", NSStringFromSelector(aSelector));
    NSMethodSignature* signature = [super methodSignatureForSelector:aSelector];
    if (!signature) {
        signature = [[[TestClass alloc] init] methodSignatureForSelector:aSelector];
    }
    return signature;
}

+ (NSMethodSignature *)instanceMethodSignatureForSelector:(SEL)aSelector {
    NSLog(@"instanceMethodSignatureForSelector %@", NSStringFromSelector(aSelector));
    NSMethodSignature* signature = [super methodSignatureForSelector:aSelector];
    if (!signature) {
        signature = [self methodSignatureForSelector:aSelector];
    }
    return signature;
}

- (void)doesNotRecognizeSelector:(SEL)aSelector {
    NSLog(@"doesNotRecognizeSelector %@", NSStringFromSelector(aSelector));
}

void hhhhImp() {
    NSLog(@"hello hhhh");
}

#pragma mark - Event Handle Test JSPatch amends crash

- (IBAction)btnClick:(id)sender {
    NSLog(@"Hello world");
    NSArray *arrTest = @[@"1"];
    @try {
        NSString *strCrash = [arrTest objectAtIndex:2];
        NSLog(@"strCrash %@", strCrash);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Click" message:@"Success" delegate:nil cancelButtonTitle:@"Yes" otherButtonTitles:nil, nil];
        [alert show];
    } @catch (NSException *exception) {
        NSLog(@"exception is %@", exception);
    } @finally {
        NSLog(@"finally");
    }
}

- (IBAction)evaluateJsPatch:(id)sender {
    [self testJSPatch];
}

- (void)testJSPatch {
//    [JPEngine startEngine];
    NSString *strJsPath = [[NSBundle mainBundle] pathForResource:@"main" ofType:@"js"];
    NSLog(@" strJsPath %@", strJsPath);
    JSValue *resultValue = [JPEngine evaluateScriptWithPath:strJsPath];
    NSLog(@"resultValue %@", resultValue);
}

@end
