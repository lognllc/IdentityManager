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

@interface FBSession ()

- (void)sendNotification;
- (void)validateSlotNumber:(int)slot;

@end

@implementation FacebookSessions

@synthesize currentSession;
@synthesize pendingRequest;

- (FBSessionTokenCachingStrategy *)createCachingStrategyForSlot:(int)slot
{
	return [[FBSessionTokenCachingStrategy alloc] initWithUserDefaultTokenInformationKeyName:[self tokenKeyForSlot:slot]];
}

- (FBSession *)sessionForSlot:(int)slot
{
	FBSessionTokenCachingStrategy *tokenCachingStrategy = [self createCachingStrategyForSlot:slot];
	
	FBSession *session = [[FBSession alloc] initWithAppID:nil
											  permissions:nil
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

- (void)removeUserInSlot:(int)slot
{
	[self validateSlotNumber:slot];
	NSString *idKey = [self idKeyForSlot:slot];
	NSString *nameKey = [self nameKeyForSlot:slot];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSLog(@"clearing slot %d", slot);
	// Can't be current user anymore
	
	FBSessionTokenCachingStrategy *tokenCachingStrategy = [self createCachingStrategyForSlot:slot];
	[tokenCachingStrategy clearToken];
	
	[defaults removeObjectForKey:idKey];
	[defaults removeObjectForKey:nameKey];
	[defaults synchronize];
	[self sendNotification];
}

- (void)updateUser:(NSDictionary *)user inSlot:(int)slot
{
	if (!user) return [self removeUserInSlot:slot];
	[self validateSlotNumber:slot];
	
	NSString *idKey = [self idKeyForSlot:slot];
	NSString *nameKey = [self nameKeyForSlot:slot];
	NSString *userId = user[@"id"];

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSLog(@"updating slot %d: fbid = %@, name = %@", slot, userId, user[@"name"]);
	[defaults setObject:userId forKey:idKey];
	[defaults setObject:user[@"name"] forKey:nameKey];
	
	[defaults synchronize];
	
	[self sendNotification];
}

- (FBSession *)switchToUserInSlot:(int)slot
{
	[self validateSlotNumber:slot];
	NSLog(@"switching to slot %d %@", slot, [self userIDInSlot:slot]);
	FBSession *session = [self sessionForSlot:slot];
	currentSession = session;
	[self sendNotification];
	return session;
}

- (void)loginSlot:(int)slot completion:(void (^)(BOOL))completion
{
	if (slot < 0 || slot >= self.maximumUserSlots) {
		if (completion) completion(NO);
		return;
	}
	// If we can't log in as new user, we don't want to still be logged in as previous user,
	// particularly if it might not be obvious to the user that the login failed.
	self.pendingLoginForSlot = slot;
	
	FBSessionLoginBehavior behavior = (slot == 0) ?
	FBSessionLoginBehaviorWithFallbackToWebView :
	FBSessionLoginBehaviorForcingWebView;
	
	FBSession *session = [self switchToUserInSlot:slot];
	
	// we pass the correct behavior here to indicate the login workflow to use (Facebook Login, fallback, etc.)
	[session openWithBehavior:behavior
			completionHandler:^(FBSession *session,
								FBSessionState status,
								NSError *error) {
				// this handler is called back whether the login succeeds or fails; in the
				// success case it will also be called back upon each state transition between
				// session-open and session-close
				[self updateForSessionChangeForSlot:slot completion:completion];
			}];
}

+ (NSString *)socialIdentifier
{
	return @"fb";
}

- (void)handleOpenURL:(NSURL *)URL
{
	[currentSession handleOpenURL:URL];
}

- (void)updateForSessionChangeForSlot:(int)slot completion:(void (^)(BOOL))completion
{
	FBSession *session = self.currentSession;
	if (session.isOpen) {
#ifdef _SOCIALSESSIONS_FACEBOOK_TOKEN_ONLY_
		self.pendingLoginForSlot = -1;
		int numSlots = [self maximumUserSlots];
		NSString *token = session.accessToken;
		for (int i = 0; i < numSlots; i++) {
			if (i != slot && [[self userTokenInSlot:i] isEqualToString:token]) {
				[self removeUserInSlot:i];
			}
		}
		[self sendNotification];
		if (completion) completion(YES);
#else
		// fetch profile info such as name, id, etc. for the open session
		FBRequest *me = [[FBRequest alloc] initWithSession:session
												 graphPath:@"me"];
		
		pendingRequest = me;
		
		[me startWithCompletionHandler:^(FBRequestConnection *connection,
										 NSDictionary<FBGraphUser> *result,
										 NSError *error) {
			// because we have a cached copy of the connection, we can check
			// to see if this is the connection we care about; a prematurely
			// cancelled connection will short-circuit here
			if (me != pendingRequest) {
				if (completion) completion(NO);
				return;
			}
			
			pendingRequest = nil;
			self.pendingLoginForSlot = -1;
			
			// we interpret an error in the initial fetch as a reason to
			// fail the user switch, and leave the application without an
			// active user (similar to initial state)
			if (error) {
				if (completion) completion(NO);
				NSLog(@"Couldn't switch user: %@", error.localizedDescription);
				return;
			}
			[self updateUser:result inSlot:slot];
			if (completion) completion(YES);
		}];
#endif
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
