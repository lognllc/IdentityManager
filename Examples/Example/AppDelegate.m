//
//  AppDelegate.m
//  Example
//
//  Created by Rex Sheng on 10/25/12.
//  Copyright (c) 2012 LogN LLC. All rights reserved.
//

#import "AppDelegate.h"
#import "FacebookSessions.h"
#import "IdentityManager.h"
#import "FacebookSessions.h"
#import "TwitterSessions.h"
#import "LinkedInSessions.h"

@implementation AppDelegate
{
	IdentityManager *identityManager;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
	identityManager = [[IdentityManager alloc] initWithPrefix:@"Demo" maximumUserSlots:7];
	[identityManager registerSocialSessionsClass:[FacebookSessions class]];
	[identityManager registerSocialSessionsClass:[TwitterSessions class]];
	[identityManager registerSocialSessionsClass:[LinkedInSessions class]];
	
    [self.window makeKeyAndVisible];
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
	return [identityManager handleOpenURL:url];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
