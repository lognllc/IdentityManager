// OAuth1Client.m
//
//  Created by Rex Sheng on 10/16/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "OAuth1Client.h"
#import "AFHTTPRequestOperation.h"
#import "OAuth1.h" 

@implementation OAuth1Client
{
	NSString *key;
	NSString *secret;
	NSString *accessTokenPath;
	NSString *requestTokenPath;
	NSString *authorizePath;
	NSURL *callbackURL;
	success_block_t successBlock;
	failure_block_t failureBlock;
	NSString *userSecret;
}

- (id)initWithBaseURL:(NSURL *)url
                  key:(NSString *)clientID
               secret:(NSString *)_secret
	 requestTokenPath:(NSString *)_requestTokenPath
		authorizePath:(NSString *)_authorizePath
	  accessTokenPath:(NSString *)_accessTokenPath
		  callbackURL:(NSURL *)_callbackURL
{
    if (self = [super initWithBaseURL:url]) {
		key = clientID;
		secret = _secret;
		accessTokenPath = _accessTokenPath;
		requestTokenPath = _requestTokenPath;
		authorizePath = _authorizePath;
		callbackURL = _callbackURL;
	}
	return self;
}

- (void)authorizeSuccess:(success_block_t)success failure:(failure_block_t)failure
{
	successBlock = success;
	failureBlock = failure;
    [self acquireOAuthRequestTokenSuccess:^(NSString *requestToken, NSString *requestTokenSecret) {
		NSLog(@"leaving app...");
		userSecret = requestTokenSecret;
        [[UIApplication sharedApplication] openURL:[[self requestWithMethod:@"GET" path:authorizePath parameters:@{@"oauth_token": requestToken}] URL]];
    } failure:nil];
}

- (BOOL)handleOpenURL:(NSURL *)url
{
	if ([url.query hasPrefix:@"denied"] || [url.query hasSuffix:@"refused"]) {
		NSLog(@"denied");
		if (failureBlock) {
			NSError *error = [NSError errorWithDomain:@"com.lognllc.OAuth" code:401 userInfo:@{NSLocalizedDescriptionKey:@"you have canceled authentication"}];
			failureBlock(error);
			successBlock = nil;
			failureBlock = nil;
		}
		return YES;
	}
	NSDictionary *oauthParam = ParametersFromQueryString(url.query);
	NSLog(@"oauthParam %@", oauthParam);
	
	[self acquireOAuthAccessTokenWithPath:accessTokenPath token:oauthParam[@"oauth_token"] verifier:oauthParam[@"oauth_verifier"] success:^(NSDictionary *data) {
		if (successBlock) successBlock(data);
		successBlock = nil;
		failureBlock = nil;
	} failure:^(NSError *error) {
		if (failureBlock) failureBlock(error);
		successBlock = nil;
		failureBlock = nil;
	}];
	return YES;
}

- (void)acquireOAuthRequestTokenSuccess:(void (^)(NSString *requestToken, NSString *requestTokenSecret))success
								failure:(failure_block_t)failure
{
	NSMutableURLRequest *request = [self requestWithMethod:@"POST" path:requestTokenPath parameters:@{@"oauth_callback": callbackURL.absoluteString}];
	NSString *oauthString = OAuthorizationHeader(request.URL, @"POST", request.HTTPBody, key, secret, nil, @"");
	[request setHTTPShouldHandleCookies:NO];
	[request setValue:oauthString forHTTPHeaderField:@"Authorization"];
	
	[self enqueueHTTPRequestOperation:[self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSDictionary *oauthParam = ParametersFromQueryString([operation responseString]);
		NSLog(@"got request token: %@", oauthParam);
		if (success) success(oauthParam[@"oauth_token"], oauthParam[@"oauth_token_secret"]);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (failure) failure(error);
		else NSLog(@"error %@", error);
	}]];
}

- (void)acquireOAuthAccessTokenWithPath:(NSString *)path
								  token:(NSString *)token
							   verifier:(NSString *)verifier
								success:(success_block_t)success
								failure:(failure_block_t)failure
{
	NSMutableURLRequest *request = [self requestWithMethod:@"POST" path:path parameters:@{@"oauth_verifier": verifier}];
	NSString *oauthString = OAuthorizationHeader(request.URL, @"POST", request.HTTPBody, key, secret, token, userSecret);
	[request setHTTPShouldHandleCookies:NO];
	[request setValue:oauthString forHTTPHeaderField:@"Authorization"];
	
	[self enqueueHTTPRequestOperation:[self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSDictionary *oauthParam = ParametersFromQueryString([operation responseString]);
		if (success) success(oauthParam);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (failure) failure(error);
		else NSLog(@"error %@", error);
	}]];
}

@end
