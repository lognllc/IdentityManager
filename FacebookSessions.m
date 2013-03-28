//
//  FacebookSessions.m
//
//  Created by Rex Sheng on 10/22/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "FacebookSessions.h"
#import "SocialSessionsSubclass.h"
#import <FacebookSDK/FBSessionTokenCachingStrategy.h>
#import <FacebookSDK/FacebookSDK.h>
#import "LNUser.h"

@implementation FacebookSessions

- (NSString *)lastUsedSlotKey
{
	return [NSString stringWithFormat:@"%@FBLastUsedSlot", self.prefix];
}

- (id)initWithPrefix:(NSString *)_prefix maximumUserSlots:(int)_maximumUserSlots
{
	if (self = [super initWithPrefix:_prefix maximumUserSlots:_maximumUserSlots]) {
		[self switchToUserInSlot:[[NSUserDefaults standardUserDefaults] integerForKey:[self lastUsedSlotKey]]];
		[self openLastUsedSession:nil failure:nil];
	}
	return self;
}

- (FBSessionTokenCachingStrategy *)createCachingStrategyForSlot:(int)slot
{
	return [[FBSessionTokenCachingStrategy alloc] initWithUserDefaultTokenInformationKeyName:[self tokenKeyForSlot:slot]];
}

- (FBSession *)sessionForSlot:(int)slot
{
	FBSessionTokenCachingStrategy *tokenCachingStrategy = [self createCachingStrategyForSlot:slot];
	
	FBSession *session = [[FBSession alloc] initWithAppID:nil
#ifdef FACEBOOK_PERMISSIONS
											  permissions:[FACEBOOK_PERMISSIONS componentsSeparatedByString:@" "]
#else
											  permissions:@[@"email"]
#endif
										  urlSchemeSuffix:nil
									   tokenCacheStrategy:tokenCachingStrategy];
	return session;
}

- (NSString *)userTokenInSlot:(int)slot
{
	[self validateSlotNumber:slot];
	FBSession *session = [self sessionForSlot:slot];
	return session.accessToken;
}

- (void)setUserToken:(NSString *)token InSlot:(int)slot
{
}

- (void)openLastUsedSession:(dispatch_block_t)success failure:(dispatch_block_t)failure
{
	FBSession *session = _currentSession;

	if (session.isOpen) {
		if (success) success();
		return;
	}
	
	if (session && !session.isOpen && session.state == FBSessionStateCreatedTokenLoaded) {
        [session openWithCompletionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            if (status == FBSessionStateOpen) {
				if (success) success();
            } else {
				if (failure) failure();
			}
        }];
    } else {
		if (failure) failure();
	}
}

- (void)removeUserTokenInSlot:(int)slot
{
	FBSessionTokenCachingStrategy *tokenCachingStrategy = [self createCachingStrategyForSlot:slot];
	[tokenCachingStrategy clearToken];
	if (_currentSlot == slot) {
		[_currentSession closeAndClearTokenInformation];
		_currentSession = nil;
	}
}

- (FBSession *)switchToUserInSlot:(int)slot
{
	[self validateSlotNumber:slot];
	if (_currentSlot == slot) {
		if (_currentSession && !FB_ISSESSIONSTATETERMINAL(_currentSession.state)) return _currentSession;
	}
	FBSession *session = [self sessionForSlot:slot];
	_currentSession = session;
	_currentSlot = slot;
	[[NSUserDefaults standardUserDefaults] setInteger:_currentSlot forKey:[self lastUsedSlotKey]];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[self sendNotification];
	return session;
}

- (void)loginSlot:(int)slot behavior:(FBSessionLoginBehavior)behavior completion:(void (^)(LNUser *))completion
{
	[self validateSlotNumber:slot];
	FBSession *session = [self switchToUserInSlot:slot];
	
	if (session.isOpen) {
		return [self updateForSessionChangeForSlot:slot completion:completion];
	}
	// we pass the correct behavior here to indicate the login workflow to use (Facebook Login, fallback, etc.)
	[session openWithBehavior:behavior completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
		// this handler is called back whether the login succeeds or fails; in the
		// success case it will also be called back upon each state transition between
		// session-open and session-close
		if (error) {
			if (behavior == FBSessionLoginBehaviorUseSystemAccountIfPresent) {
				[self loginSlot:slot behavior:FBSessionLoginBehaviorWithFallbackToWebView completion:completion];
			} else {
				if (completion) completion(nil);
			}
		} else {
			[self updateForSessionChangeForSlot:slot completion:completion];
		}
	}];
}

- (void)loginSlot:(int)slot completion:(void (^)(LNUser *))completion
{
	FBSessionLoginBehavior behavior;
	
#ifdef _SOCIALSESSIONS_FACEBOOK_LOGIN_BEHAVIOR_
	behavior = _SOCIALSESSIONS_FACEBOOK_LOGIN_BEHAVIOR_;
#else
	behavior = (slot == 0) ?
	FBSessionLoginBehaviorWithFallbackToWebView :
	FBSessionLoginBehaviorForcingWebView;
#endif
	
	[self loginSlot:slot behavior:behavior completion:completion];
}

+ (NSString *)socialIdentifier
{
	return @"fb";
}

- (void)handleOpenURL:(NSURL *)URL
{
	[_currentSession handleOpenURL:URL];
}

- (void)updateForSessionChangeForSlot:(int)slot completion:(void (^)(LNUser *))completion
{
	FBSession *session = self.currentSession;
	if (session.isOpen) {
		__block LNUser *user = [self userInSlot:slot];
#ifndef _SOCIALSESSIONS_FACEBOOK_TOKEN_ONLY_
		if (!user.id || !user.name || !user.email) {
			// fetch profile info such as name, id, etc. for the open session
			FBRequest *me = [[FBRequest alloc] initWithSession:session
													 graphPath:@"me"];
			_pendingRequest = me;
			
			[me startWithCompletionHandler:^(FBRequestConnection *connection,
											 NSDictionary<FBGraphUser> *result,
											 NSError *error) {
				// because we have a cached copy of the connection, we can check
				// to see if this is the connection we care about; a prematurely
				// cancelled connection will short-circuit here
				if (me != _pendingRequest) {
					if (completion) completion(user);
					return;
				}
				
				// we interpret an error in the initial fetch as a reason to
				// fail the user switch, and leave the application without an
				// active user (similar to initial state)
				if (error) {
					if (completion) completion(nil);
					NSLog(@"Couldn't switch user: %@", error.localizedDescription);
					return;
				}
				user.id = result.id;
				user.name = result.name;
				if (result[@"email"]) user.email = result[@"email"];
				_pendingRequest = nil;
				[self updateUser:user inSlot:slot];
				if (completion) completion(user);
			}];
		} else
#endif
			if (completion) completion(user);
	} else {
		// in the closed case, we check to see if we picked up a cached token that we
		// expect to be valid and ready for use; if so then we open the session on the spot
		if (session.state == FBSessionStateCreatedTokenLoaded) {
			// even though we had a cached token, we need to login to make the session usable
			[session openWithCompletionHandler:^(FBSession *session,
												 FBSessionState status,
												 NSError *error) {
				[self updateForSessionChangeForSlot:slot completion:completion];
			}];
		}
	}
}

@end
