//
//  TwitterSessions.m
//
//  Created by Rex Sheng on 10/22/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "TwitterSessions.h"
#import "OAuth1Gateway.h"
#import "SocialSessionsSubclass.h"
#import "AFHTTPClient.h"
#import "AFJSONRequestOperation.h"

#import "OAuth1Client.h"

@interface TwitterSessions ()
@property (nonatomic, strong, readonly) OAuth1Gateway *oauth;
@end

@implementation TwitterSessions
{
	OAuth1Client *_client;
}

- (id)initWithPrefix:(NSString *)_prefix maximumUserSlots:(int)_maximumUserSlots
{
	if (self = [super initWithPrefix:_prefix maximumUserSlots:_maximumUserSlots]) {
		NSString *twitterAppID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"TwitterAppID"];
		NSURL *callbackURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@://success", [[self class] socialIdentifier], twitterAppID]];
		_oauth = [[OAuth1Gateway alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.twitter.com/oauth/"]
													key:twitterAppID
												 secret:TWITTER_SECRET
									   requestTokenPath:@"request_token"
										  authorizePath:@"authorize"
										accessTokenPath:@"access_token"
											callbackURL:callbackURL];
		
		_client = [[OAuth1Client alloc] initWithBaseURL:[NSURL URLWithString:@"http://api.twitter.com/1/"]
													key:twitterAppID
												 secret:TWITTER_SECRET];
		[_client setDefaultHeader:@"Accept" value:@"application/json"];
		[_client registerHTTPOperationClass:[AFJSONRequestOperation class]];
	}
	return self;
}

+ (NSString *)socialIdentifier
{
	return @"tw";
}

- (void)handleOpenURL:(NSURL *)URL
{
	[_oauth handleOpenURL:URL];
}

- (void)loginSlot:(int)slot completion:(void(^)(LNUser *))completion
{
	if (slot < 0 || slot >= self.maximumUserSlots) {
		if (completion) completion(nil);
		return;
	}
	[self sendNotification];
	
	[_oauth authorizeSuccess:^(NSDictionary *data) {
		
		LNUser *user = [LNUser new];
		user.id = data[@"user_id"];
		user.name = data[@"screen_name"];
		user.accessToken = data[@"oauth_token"];
		user.accessTokenSecret = data[@"oauth_token_secret"];
#ifdef _SOCIALSESSIONS_TWITTER_REQUEST_NAME_
		_client.userToken = _oauth.userToken;
		_client.userTokenSecret = _oauth.userTokenSecret;
		[_client getPath:@"users/lookup.json" parameters:@{@"user_id": user.id} success:^(AFHTTPRequestOperation *operation, id responseObject) {
			user.name = responseObject[@"name"];
#endif
			[self updateUser:user inSlot:slot];
			if (completion) completion(user);
#ifdef _SOCIALSESSIONS_TWITTER_REQUEST_NAME_
		} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			[self updateUser:user inSlot:slot];
			if (completion) completion(user);
		}];
#endif
	} failure:^(NSError *error) {
		NSLog(@"error %@", error);
		if (completion) completion(nil);
	}];
}

@end
