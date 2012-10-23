//
//  LinkedInSessions.m
//
//  Created by Rex Sheng on 10/23/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "LinkedInSessions.h"
#import "SocialSessionsSubclass.h"
#import "OAuth1Client.h"
#import "OAuth1.h"

@implementation LinkedInSessions

@synthesize client;

- (id)initWithPrefix:(NSString *)_prefix maximumUserSlots:(int)_maximumUserSlots
{
	if (self = [super initWithPrefix:_prefix maximumUserSlots:_maximumUserSlots]) {
		NSString *linkedInAppID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"LinkedInAppID"];
		NSURL *callbackURL = [NSURL URLWithString:[NSString stringWithFormat:@"li%@://success", linkedInAppID]];
		client = [[OAuth1Client alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.linkedin.com/uas/oauth/"]
												   key:linkedInAppID
												secret:LINKEDIN_SECRET
									  requestTokenPath:@"requestToken"
										 authorizePath:@"authenticate"
									   accessTokenPath:@"accessToken"
										   callbackURL:callbackURL];
	}
	return self;
}

+ (NSString *)socialIdentifier
{
	return @"li";
}

- (void)handleOpenURL:(NSURL *)URL
{
	[client handleOpenURL:URL];
}

- (void)updateUser:(NSDictionary *)user inSlot:(int)slot
{
	if (!user) return [self removeUserInSlot:slot];
	[self validateSlotNumber:slot];
	
	NSString *tokenKey = [self tokenKeyForSlot:slot];
	NSString *tokenSecretKey = [self tokenSecretKeyForSlot:slot];
	
	NSString *oauth_token = user[@"oauth_token"];
	int numSlots = [self maximumUserSlots];
	for (int i = 0; i < numSlots; i++) {
		if (i != slot && [[self userTokenInSlot:i] isEqualToString:oauth_token]) {
			[self removeUserInSlot:i];
		}
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSLog(@"updating slot %d: linkedin expires in %@ token: %@", slot, user[@"oauth_expires_in"], oauth_token);
	[defaults setObject:oauth_token forKey:tokenKey];
	[defaults setObject:[user objectForKey:@"oauth_token_secret"] forKey:tokenSecretKey];
	[defaults synchronize];
	
	[self sendNotification];
}

- (void)loginSlot:(int)slot completion:(void(^)(BOOL))completion
{
	if (slot < 0 || slot >= self.maximumUserSlots) {
		if (completion) completion(NO);
		return;
	}
	// If we can't log in as new user, we don't want to still be logged in as previous user,
	// particularly if it might not be obvious to the user that the login failed.
	self.pendingLoginForSlot = slot;
	
	[self sendNotification];
	
	[client authorizeSuccess:^(NSDictionary *data) {
		self.pendingLoginForSlot = -1;
		[self updateUser:data inSlot:slot];
		if (completion) completion(YES);
	} failure:^(NSError *error) {
		self.pendingLoginForSlot = -1;
		NSDictionary *suggestion = ParametersFromQueryString(error.localizedRecoverySuggestion);
		NSLog(@"suggestion: %@", suggestion);
		if (completion) completion(NO);
	}];
}

@end
