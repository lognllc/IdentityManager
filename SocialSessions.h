//
//  FBSessions.h
//
//  Created by Rex Sheng on 10/16/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const SUInvalidSlotNumber;

@protocol SocialSessionsTrait <NSObject>

+ (NSString *)socialIdentifier;
- (void)handleOpenURL:(NSURL *)URL;
- (NSUInteger)usedSlotCount;
- (void)loginSlot:(int)slot completion:(void(^)(BOOL success))completion;
- (int)maximumUserSlots;
- (BOOL)isSlotEmpty:(int)slot;

@end

@interface SocialSessions : NSObject

@property (readonly) int maximumUserSlots;
@property (nonatomic, readonly) NSString *prefix;
@property (nonatomic) int pendingLoginForSlot;

- (id)initWithPrefix:(NSString *)prefix;
- (id)initWithPrefix:(NSString *)_prefix maximumUserSlots:(int)_maximumUserSlots;

- (NSString *)userIDInSlot:(int)slot;
- (NSString *)userNameInSlot:(int)slot;
- (NSString *)userTokenInSlot:(int)slot;
- (NSString *)userTokenSecretInSlot:(int)slot;

- (BOOL)isSlotEmpty:(int)slot;
- (NSUInteger)usedSlotCount;
- (BOOL)areAllSlotsEmpty;

- (void)removeUserInSlot:(int)slot;

- (void)validateSlotNumber:(int)slot;
- (void)sendNotification;

+ (BOOL)canHandleURL:(NSURL *)URL;

@end
