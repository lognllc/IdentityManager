//
//  LinkedInSessions.m
//
//  Created by Rex Sheng on 10/23/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "LinkedInSessions.h"
#import "SocialSessionsSubclass.h"
#import "AFJSONRequestOperation.h"
#import "OAuth1Gateway.h"

@interface LinkedInSessions ()
@property (nonatomic, strong, readonly) OAuth1Gateway *oauth;
@end

@implementation LinkedInSessions
{
	OAuth1Client *client;
}
@synthesize oauth, client;

- (id)initWithPrefix:(NSString *)_prefix maximumUserSlots:(int)_maximumUserSlots
{
	if (self = [super initWithPrefix:_prefix maximumUserSlots:_maximumUserSlots]) {
		NSString *linkedInAppID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"LinkedInAppID"];
		NSURL *callbackURL = [NSURL URLWithString:[NSString stringWithFormat:@"li%@://success", linkedInAppID]];
		oauth = [[OAuth1Gateway alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.linkedin.com/uas/oauth/"]
												   key:linkedInAppID
												secret:LINKEDIN_SECRET
									  requestTokenPath:@"requestToken"
										 authorizePath:@"authenticate"
									   accessTokenPath:@"accessToken"
										   callbackURL:callbackURL];
#ifndef _SOCIALSESSIONS_LINKEDIN_TOKEN_ONLY_
		client = [[OAuth1Client alloc] initWithBaseURL:[NSURL URLWithString:@"http://api.linkedin.com/v1/"]
												   key:linkedInAppID
												secret:LINKEDIN_SECRET];
		[client setDefaultHeader:@"Accept" value:@"application/json"];
		[client registerHTTPOperationClass:[AFJSONRequestOperation class]];
#endif
	}
	return self;
}

+ (NSString *)socialIdentifier
{
	return @"li";
}

- (void)handleOpenURL:(NSURL *)URL
{
	[oauth handleOpenURL:URL];
}

- (void)updateUser:(NSDictionary *)user inSlot:(int)slot
{
	if (!user) return [self removeUserInSlot:slot];
	[self validateSlotNumber:slot];
	
	NSString *tokenKey = [self tokenKeyForSlot:slot];
	NSString *nameKey = [self nameKeyForSlot:slot];
	NSString *tokenSecretKey = [self tokenSecretKeyForSlot:slot];
	
	NSString *oauth_token = user[@"oauth_token"];
	int numSlots = [self maximumUserSlots];
	for (int i = 0; i < numSlots; i++) {
		if (i != slot && [[self userTokenInSlot:i] isEqualToString:oauth_token]) {
			[self removeUserInSlot:i];
		}
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:oauth_token forKey:tokenKey];
	[defaults setObject:[user objectForKey:@"oauth_token_secret"] forKey:tokenSecretKey];
	NSString *name = user[@"username"];
	if (name) {
		[defaults setObject:name forKey:nameKey];
	}
	[defaults synchronize];
	NSLog(@"updating slot %d: linkedin '%@' expires in %@", slot, name ?: oauth_token, user[@"oauth_expires_in"]);

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
	
	[oauth authorizeSuccess:^(NSDictionary *data) {
		self.pendingLoginForSlot = -1;
		
#ifdef _SOCIALSESSIONS_LINKEDIN_TOKEN_ONLY_
		[self updateUser:data inSlot:slot];
		if (completion) completion(YES);
#else
		client.userToken = oauth.userToken;
		client.userTokenSecret = oauth.userTokenSecret;
		[client getPath:@"people/~" parameters:@{@"format": @"json"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
			NSMutableDictionary *mdata = [data mutableCopy];
			NSMutableString *name = [NSMutableString stringWithString:responseObject[@"firstName"]];
			NSString *lastName = responseObject[@"lastName"];
			if (name.length && lastName.length) [name appendString:@" "];
			[name appendString:lastName];
			mdata[@"username"] = name;
			[self updateUser:mdata inSlot:slot];
			if (completion) completion(YES);
		} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			[self updateUser:data inSlot:slot];
			if (completion) completion(YES);
		}];
#endif
	} failure:^(NSError *error) {
		self.pendingLoginForSlot = -1;
		NSDictionary *suggestion = [NSURL ab_parseURLQueryString:error.localizedRecoverySuggestion];
		NSLog(@"suggestion: %@", suggestion);
		if (completion) completion(NO);
	}];
}

@end
