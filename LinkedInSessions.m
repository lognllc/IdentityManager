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

@synthesize client;

- (id)initWithPrefix:(NSString *)_prefix maximumUserSlots:(int)_maximumUserSlots
{
	if (self = [super initWithPrefix:_prefix maximumUserSlots:_maximumUserSlots]) {
		NSString *linkedInAppID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"LinkedInAppID"];
		NSURL *callbackURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@://success", [[self class] socialIdentifier], linkedInAppID]];
		_oauth = [[OAuth1Gateway alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.linkedin.com/uas/oauth/"]
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
	[_oauth handleOpenURL:URL];
}

- (void)loginSlot:(int)slot completion:(void (^)(LNUser *))completion
{
	if (slot < 0 || slot >= self.maximumUserSlots) {
		if (completion) completion(nil);
		return;
	}
	
	[self sendNotification];
	
	[_oauth authorizeSuccess:^(NSDictionary *data) {
		LNUser *user = [LNUser new];
		user.accessToken = data[@"oauth_token"];
		user.accessTokenSecret = data[@"oauth_token_secret"];
		
#ifdef _SOCIALSESSIONS_LINKEDIN_TOKEN_ONLY_
		[self updateUser:user inSlot:slot];
		if (completion) completion([self userInSlot:slot]);
#else
		client.userToken = _oauth.userToken;
		client.userTokenSecret = _oauth.userTokenSecret;
		[client getPath:@"people/~" parameters:@{@"format": @"json"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
			NSMutableString *name = [NSMutableString stringWithString:responseObject[@"firstName"]];
			NSString *lastName = responseObject[@"lastName"];
			if (name.length && lastName.length) [name appendString:@" "];
			[name appendString:lastName];
			user.name = name;
			[self updateUser:user inSlot:slot];
			if (completion) completion(user);
		} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			[self updateUser:user inSlot:slot];
			if (completion) completion(user);
		}];
#endif
	} failure:^(NSError *error) {
		NSDictionary *suggestion = [NSURL ab_parseURLQueryString:error.localizedRecoverySuggestion];
		NSLog(@"suggestion: %@", suggestion);
		if (completion) completion(nil);
	}];
}

@end
