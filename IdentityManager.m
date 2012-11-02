//
//  IdentityManager.m
//
//  Created by Rex Sheng on 10/22/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "IdentityManager.h"
#import "OAuth1Gateway.h"
#import "SocialSessions.h"

@interface IdentityManager ()

@property (strong, nonatomic) NSMutableArray *registeredSocialSessions;
@property (strong, nonatomic) NSMutableDictionary *sessionsObjects;
@property (strong, nonatomic) NSString *prefix;
@property (nonatomic) int slots;

@end

@implementation IdentityManager

- (id)initWithPrefix:(NSString *)prefix maximumUserSlots:(int)slots
{
	if (self = [super init]) {
		_prefix = prefix;
		_slots = slots;
		_registeredSocialSessions = [NSMutableArray arrayWithCapacity:3];
		_sessionsObjects = [NSMutableDictionary dictionaryWithCapacity:3];
	}
	return self;
}

- (BOOL)registerSocialSessionsClass:(Class)sessionClass
{
	if (![sessionClass conformsToProtocol:@protocol(SocialSessionsTrait)]) {
		return NO;
	}
	NSString *identifier = [sessionClass socialIdentifier];
	
	id sessions = [[sessionClass alloc] initWithPrefix:_prefix maximumUserSlots:_slots];
	_sessionsObjects[identifier] = sessions;
	[_registeredSocialSessions removeObject:identifier];
	[_registeredSocialSessions insertObject:identifier atIndex:0];
    return YES;
}

- (void)unregisterSocialSessionsClass:(Class)sessionClass
{
	if (![sessionClass conformsToProtocol:@protocol(SocialSessionsTrait)]) {
		return;
	}
	NSString *identifier = [sessionClass socialIdentifier];
	[_sessionsObjects removeObjectForKey:identifier];
    [_registeredSocialSessions removeObject:identifier];
}

- (int)authenticateIdentityWithServiceIdentifier:(NSString *)identifier completion:(void(^)(BOOL))completion
{
	id<SocialSessionsTrait> sessions = [self registeredSocialSessionsWithServiceIdentifier:identifier];
	if (sessions) {
		int maxCount = [sessions maximumUserSlots];
		for (int i = 0; i < maxCount; i++) {
			if ([sessions isSlotEmpty:i]) {
				[sessions loginSlot:i completion:completion];
				return i;
			}
		}
		NSLog(@"no slot is empty");
	} else {
		NSLog(@"identifier '%@' does not match any registered socialsessions", identifier);
	}
	return -1;
}

- (BOOL)handleOpenURL:(NSURL *)url
{
	__block BOOL handled = NO;
	[[_sessionsObjects allValues] enumerateObjectsUsingBlock:^(id<SocialSessionsTrait> obj, NSUInteger idx, BOOL *stop) {
		if ([[obj class] canHandleURL:url]) {
			[obj handleOpenURL:url];
			handled = YES;
			*stop = YES;
		}
	}];
	return handled;
}

- (id<SocialSessionsTrait>)registeredSocialSessionsWithServiceIdentifier:(NSString *)identifier
{
	return _sessionsObjects[identifier];
}

@end
