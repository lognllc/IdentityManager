//
//  OAuth1.h
//
//  Created by Rex Sheng on 10/16/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *OAuthorizationHeader(NSURL *url, NSString *method, NSData *body, NSString *_oAuthConsumerKey, NSString *_oAuthConsumerSecret, NSString *_oAuthToken, NSString *_oAuthTokenSecret);

extern NSDictionary *ParametersFromQueryString(NSString *queryString);