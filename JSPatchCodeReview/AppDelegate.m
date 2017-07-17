//
//  AppDelegate.m
//  JSPatchCodeReview
//
//  Created by Semyon on 2017/4/25.
//  Copyright © 2017年 Semyon. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    return YES;
}

// test
// 适配语音金额，可以播放所有本地音频：100以上的去掉小数，0.1-99.99去掉分
- (NSString *)fixMoneyToAdaptSounds:(NSString *)strOriMoney {
    NSString *strMoney = [strOriMoney copy];
    NSUInteger pointIndex = [strMoney rangeOfString:@"."].location;
    if (pointIndex == NSNotFound) {
        
        return strMoney;
    }
   
    double curMoney = [strMoney doubleValue];
    if (curMoney > 0.1 && curMoney < 100) {
        if (strMoney.length > pointIndex + 1) {
         
            return [strMoney substringToIndex:pointIndex + 2];
        }
    }
    else if (curMoney > 100 && curMoney < 1000) {
        
        return [strMoney substringToIndex:pointIndex];
    }
    
    return strMoney;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
