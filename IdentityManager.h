//
//  IdentityManager.h
//
//  Created by Rex Sheng on 10/22/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SocialSessions.h"

@interface IdentityManager : NSObject

- (id)initWithPrefix:(NSString *)prefix maximumUserSlots:(int)slots;

- (BOOL)handleOpenURL:(NSURL *)url;

- (BOOL)registerSocialSessionsClass:(Class)sessionClass;
- (void)unregisterSocialSessionsClass:(Class)sessionClass;

- (id<SocialSessionsTrait>)registeredSocialSessionsWithServiceIdentifier:(NSString *)identifier;

- (int)authenticateIdentityWithServiceIdentifier:(NSString *)identifier completion:(void(^)(LNUser *))completion;

@end
