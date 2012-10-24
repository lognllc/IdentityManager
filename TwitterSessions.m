//
//  TwitterSessions.m
//
//  Created by Rex Sheng on 10/22/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "TwitterSessions.h"
#import "OAuth1Gateway.h"
#import "SocialSessionsSubclass.h"

@interface TwitterSessions ()

@property (nonatomic, strong, readonly) OAuth1Gateway *client;

@end


@implementation TwitterSessions

@synthesize client;

- (id)initWithPrefix:(NSString *)_prefix maximumUserSlots:(int)_maximumUserSlots
{
	if (self = [super initWithPrefix:_prefix maximumUserSlots:_maximumUserSlots]) {
		NSString *twitterAppID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"TwitterAppID"];
		NSURL *callbackURL = [NSURL URLWithString:[NSString stringWithFormat:@"tw%@://success", twitterAppID]];
		client = [[OAuth1Gateway alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.twitter.com/oauth/"]
												   key:twitterAppID
												secret:TWITTER_SECRET
									  requestTokenPath:@"request_token"
										 authorizePath:@"authorize"
									   accessTokenPath:@"access_token"
										   callbackURL:callbackURL];
	}
	return self;
}

+ (NSString *)socialIdentifier
{
	return @"tw";
}

- (void)handleOpenURL:(NSURL *)URL
{
	[client handleOpenURL:URL];
}

- (void)updateUser:(NSDictionary *)user inSlot:(int)slot
{
	if (!user) return [self removeUserInSlot:slot];
	[self validateSlotNumber:slot];
	
	NSString *idKey = [self idKeyForSlot:slot];
	NSString *nameKey = [self nameKeyForSlot:slot];
	NSString *tokenKey = [self tokenKeyForSlot:slot];
	NSString *tokenSecretKey = [self tokenSecretKeyForSlot:slot];
	
	NSString *userId = user[@"user_id"];
	int numSlots = [self maximumUserSlots];
	for (int i = 0; i < numSlots; i++) {
		if (i != slot && [[self userIDInSlot:i] isEqualToString:userId]) {
			[self removeUserInSlot:i];
		}
	}
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSLog(@"updating slot %d: tw_id = %@, name = %@", slot, userId, user[@"screen_name"]);
	[defaults setObject:userId forKey:idKey];
	[defaults setObject:user[@"screen_name"] forKey:nameKey];
	[defaults setObject:user[@"oauth_token"] forKey:tokenKey];
	[defaults setObject:user[@"oauth_token_secret"] forKey:tokenSecretKey];
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
		NSLog(@"error %@", error);
		if (completion) completion(NO);
	}];
}

@end
