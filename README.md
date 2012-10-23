IdentityManager
===============

IdentityManager maintains multiple accounts on each oauth platform, bundled with facebook, twitter, linkedin support. But you can register as many OAuth 1.0a services as you can.

Requirement
===========

IdentityManager requires [FacebookSDK.framework(v3.1.1)](https://github.com/b051/FacebookSDK.framework) and [AFNetworking](https://github.com/AFNetworking/AFNetworking)
You probably need to compile this with LLVM4.0 and xCode4.5.

Usage
=====

You can specify a namespace and maximum slots when creating `IdentityManager`

```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	identityManager = [[IdentityManager alloc] initWithPrefix:@"VH" maximumUserSlots:7];
	...
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
	return [identityManager handleOpenURL:url];
}
```

To fully work with Facebook, you need to add `FacebookAppID` and proper `URL Types` to your `info.plist`, and register it using

```objective-c
[identityManager registerSocialSessionsClass:[FacebookSessions class]];
```

For Twitter and LinkedIn, you need to add `TwitterAppID` or `LinkedInAppID` using `app_key` and `tw[app_key]` or `li[app_key]` as `URL Types`, and register it using

```objective-c
// you probably want to add these to your prefix.pch file.
#define TWITTER_SECRET @"xxxxx"
#define LINKEDIN_SECRET @"xxxxx"

[identityManager registerSocialSessionsClass:[TwitterSessions class]];    
[identityManager registerSocialSessionsClass:[LinkedInSessions class]];
```
