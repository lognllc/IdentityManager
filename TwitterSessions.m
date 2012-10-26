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
		NSURL *callbackURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@://success", [[self class] socialIdentifier], twitterAppID]];
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
				
		LNUser *user = [LNUser new];
		user.id = data[@"user_id"];
		user.name = data[@"screen_name"];
		user.accessToken = data[@"oauth_token"];
		user.accessTokenSecret = data[@"oauth_token_secret"];
		[self updateUser:user inSlot:slot];
		
		if (completion) completion(YES);
	} failure:^(NSError *error) {
		self.pendingLoginForSlot = -1;
		NSLog(@"error %@", error);
		if (completion) completion(NO);
	}];
}

@end
