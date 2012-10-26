//
//  LinkedInSessions.h
//
//  Created by Rex Sheng on 10/23/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "SocialSessions.h"

#ifndef LINKEDIN_SECRET
#warning "undefine LINKEDIN_SECRET"
#define LINKEDIN_SECRET
#endif
@class OAuth1Client;

@interface LinkedInSessions : SocialSessions <SocialSessionsTrait>

@property (nonatomic, strong, readonly) OAuth1Client *client;

@end
