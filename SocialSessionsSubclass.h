//
//  SocialSessions+Subclassing.h
//
//  Created by Rex Sheng on 10/23/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "SocialSessions.h"

@interface SocialSessions (ForSubclassEyesOnly)

- (NSString *)idKeyForSlot:(int)slot;
- (NSString *)nameKeyForSlot:(int)slot;
- (NSString *)tokenKeyForSlot:(int)slot;
- (NSString *)tokenSecretKeyForSlot:(int)slot;
- (void)updateUser:(NSDictionary *)user inSlot:(int)slot;

@end
