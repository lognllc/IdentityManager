//
//  IdentityManager.m
//
//  Created by Rex Sheng on 10/22/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "IdentityManager.h"
#import "OAuth1Client.h"
#import "SocialSessions.h"
#import "FacebookSessions.h"
#import "TwitterSessions.h"
#import "LinkedInSessions.h"

@interface IdentityManager ()

@property (readwrite, nonatomic) NSMutableArray *registeredSocialSessions;

@end

@implementation IdentityManager
{
	NSString *prefix;
	int slots;
	NSMutableDictionary *sessionsObjects;
}

@synthesize registeredSocialSessions;

- (id)initWithPrefix:(NSString *)_prefix maximumUserSlots:(int)_slots
{
	if (self = [super init]) {
		prefix = _prefix;
		slots = _slots;
		registeredSocialSessions = [NSMutableArray arrayWithCapacity:3];
		sessionsObjects = [NSMutableDictionary dictionaryWithCapacity:3];
		[self registerSocialSessionsClass:[FacebookSessions class]];
		[self registerSocialSessionsClass:[TwitterSessions class]];
		[self registerSocialSessionsClass:[LinkedInSessions class]];
	}
	return self;
}

- (BOOL)registerSocialSessionsClass:(Class)sessionClass
{
	if (![sessionClass conformsToProtocol:@protocol(SocialSessionsTrait)]) {
		return NO;
	}
	NSString *identifier = [sessionClass socialIdentifier];
	
	id sessions = [[sessionClass alloc] initWithPrefix:prefix maximumUserSlots:slots];
	[sessionsObjects setObject:sessions forKey:identifier];
	[self.registeredSocialSessions removeObject:identifier];
	[self.registeredSocialSessions insertObject:identifier atIndex:0];
    return YES;
}

- (void)unregisterSocialSessionsClass:(Class)sessionClass
{
	if (![sessionClass conformsToProtocol:@protocol(SocialSessionsTrait)]) {
		return;
	}
	NSString *identifier = [sessionClass socialIdentifier];
	[sessionsObjects removeObjectForKey:identifier];
    [self.registeredSocialSessions removeObject:identifier];
}

- (int)authenticateIdentityWithServiceIdentifier:(NSString *)identifier completion:(void(^)(BOOL))completion
{
	SocialSessions<SocialSessionsTrait> *sessions = [sessionsObjects objectForKey:identifier];
	if (sessions) {
		int maxCount = sessions.maximumUserSlots;
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

- (NSUInteger)identitiesCountWithServiceIdentifier:(NSString *)identifier
{
	SocialSessions<SocialSessionsTrait> *sessions = [sessionsObjects objectForKey:identifier];
	if (sessions) {
		return [sessions usedSlotCount];
	}
	return NSNotFound;
}

- (BOOL)handleOpenURL:(NSURL *)url
{
	__block BOOL handled = NO;
	[[sessionsObjects allValues] enumerateObjectsUsingBlock:^(id<SocialSessionsTrait> obj, NSUInteger idx, BOOL *stop) {
		if ([[obj class] canHandleURL:url]) {
			[obj handleOpenURL:url];
			handled = YES;
			*stop = YES;
		}
	}];
	return handled;
}

@end
