//
//  TwitterSessions.h
//
//  Created by Rex Sheng on 10/22/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "SocialSessions.h"

#ifndef TWITTER_SECRET
#warning "to use TwitterSessions you should define TWITTER_SECRET"
#define TWITTER_SECRET @""
#endif

@interface TwitterSessions : SocialSessions <SocialSessionsTrait>

@end
