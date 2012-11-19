// OAuth1Client.m
//
//  Created by Rex Sheng on 10/16/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "OAuth1Gateway.h"
#import "AFHTTPRequestOperation.h"

@implementation OAuth1Gateway
{
	NSString *accessTokenPath;
	NSString *requestTokenPath;
	NSString *authorizePath;
	NSURL *callbackURL;
	success_block_t successBlock;
	failure_block_t failureBlock;
}

- (id)initWithBaseURL:(NSURL *)url
                  key:(NSString *)clientID
               secret:(NSString *)_secret
	 requestTokenPath:(NSString *)_requestTokenPath
		authorizePath:(NSString *)_authorizePath
	  accessTokenPath:(NSString *)_accessTokenPath
		  callbackURL:(NSURL *)_callbackURL
{
    if (self = [super initWithBaseURL:url key:clientID secret:_secret]) {
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
    [self acquireOAuthRequestTokenSuccess:^(NSDictionary *_) {
		NSLog(@"leaving app...");
        [[UIApplication sharedApplication] openURL:[[self requestWithMethod:@"GET" path:authorizePath parameters:@{@"oauth_token": self.userToken}] URL]];
    } failure:failure];
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
	NSDictionary *oauthParam = [NSURL ab_parseURLQueryString:url.query];
	NSLog(@"oauthParam %@", oauthParam);
	
	self.userToken = oauthParam[@"oauth_token"];
	[self acquireOAuthAccessTokenSuccess:^(NSDictionary *data) {
		if (successBlock) successBlock(data);
		successBlock = nil;
		failureBlock = nil;
	} failure:^(NSError *error) {
		if (failureBlock) failureBlock(error);
		successBlock = nil;
		failureBlock = nil;
	} verifier:oauthParam[@"oauth_verifier"]];
	return YES;
}

- (void)enqueueRequest:(NSURLRequest *)request success:(success_block_t)success failure:(failure_block_t)failure
{
	[self enqueueHTTPRequestOperation:[self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSDictionary *oauthParam = [NSURL ab_parseURLQueryString:operation.responseString];
		self.userToken = oauthParam[@"oauth_token"];
		self.userTokenSecret = oauthParam[@"oauth_token_secret"];
		NSLog(@"got request token: %@", oauthParam);
		if (success) success(oauthParam);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		self.userToken = nil;
		self.userTokenSecret = @"";
		if (failure) failure(error);
		else NSLog(@"error %@", error);
	}]];
}

- (void)acquireOAuthRequestTokenSuccess:(success_block_t)success failure:(failure_block_t)failure
{
	NSURLRequest *request = [self requestWithMethod:@"POST" path:requestTokenPath parameters:@{@"oauth_callback": callbackURL.absoluteString}];
	[self enqueueRequest:request success:success failure:failure];
}

- (void)acquireOAuthAccessTokenSuccess:(success_block_t)success failure:(failure_block_t)failure verifier:(NSString *)verifier
{
	NSURLRequest *request = [self requestWithMethod:@"POST" path:accessTokenPath parameters:@{@"oauth_verifier": verifier}];
	[self enqueueRequest:request success:success failure:failure];
}

@end
