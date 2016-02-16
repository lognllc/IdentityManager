IdentityManager
===============

IdentityManager maintains multiple accounts on each oauth platform, bundled with facebook, twitter, linkedin support. But you can register as many OAuth 1.0a services as you can.

This project was inspired by the following projects:

* AFOAuth1Client
* TWiOS5ReverseAuthExample
* RSOAuthEngine
* SwitchUserSample from FacebookSDK

Requirement
===========

IdentityManager requires [FacebookSDK.framework(v3.1.1)](https://github.com/b051/FacebookSDK.framework) and [AFNetworking](https://github.com/AFNetworking/AFNetworking).

Also you'd best using LLVM4.0 and Xcode4.5 to compile. If you are having trouble with lower edition, try adding my submodule [ObjectiveCLiterals](https://github.com/b051/ObjectiveCLiterals)

Getting Start
=============

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

`FaceboookSessions` will start a new request and get `id` and `name` for you, but you can stop the request from being sent by using `_SOCIALSESSIONS_FACEBOOK_TOKEN_ONLY_`.

For Twitter and LinkedIn, you need to add `TwitterAppID` and `LinkedInAppID` using the `app_key` they give you and add `tw[app_key]` and `li[app_key]` as `URL Types`, and register them using:

```objective-c
// you probably want to add these to your prefix.pch file.
#define TWITTER_SECRET @"xxxxx"
#define LINKEDIN_SECRET @"xxxxx"

  [identityManager registerSocialSessionsClass:[TwitterSessions class]];    
  [identityManager registerSocialSessionsClass:[LinkedInSessions class]];
```
                          
Finally start registration like this:

```objective-c
  [identityManager authenticateIdentityWithServiceIdentifier:[TwitterSessions socialIdentifier] completion:^(BOOL success) {
	  NSLog(@"done!");
  }];
```
