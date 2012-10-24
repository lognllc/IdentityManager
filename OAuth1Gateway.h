//
//  OAuth1Client.h
//
//  Created by Rex Sheng on 10/16/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "OAuth1Client.h"

typedef void (^success_block_t) (NSDictionary *);
typedef void (^failure_block_t) (NSError *);

@interface OAuth1Gateway : OAuth1Client

- (id)initWithBaseURL:(NSURL *)url
                  key:(NSString *)clientID
               secret:(NSString *)_secret
	 requestTokenPath:(NSString *)_requestTokenPath
		authorizePath:(NSString *)_authorizePath
	  accessTokenPath:(NSString *)_accessTokenPath
		  callbackURL:(NSURL *)callbackURL;

- (void)authorizeSuccess:(success_block_t)success failure:(failure_block_t)failure;

- (BOOL)handleOpenURL:(NSURL *)url;

@end