//
//  MBProgressHUD+Appearance.m
//  viralheat
//
//  Created by Rex Sheng on 11/28/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "MBProgressHUD+Appearance.h"
#import <objc/runtime.h>

NSString * const HUDAttributeSquare = @"square";
NSString * const HUDAttributeUppercase = @"uppercase";
NSString * const HUDAttributeCustomImage = @"custom.image";
NSString * const HUDArrributeLabelFont = @"labelFont.name";
NSString * const HUDArrributeDetailsLabelFont = @"detailsLabelFont.name";
NSString * const HUDArrributeMargin = @"margin";

@implementation MBProgressHUD (Appearance)

static char kHUDAttributes;
- (void)setHUDAttributes:(NSDictionary *)HUDAttributes
{
	objc_setAssociatedObject(self, &kHUDAttributes, HUDAttributes, OBJC_ASSOCIATION_COPY);
}

- (NSDictionary *)HUDAttributes
{
	return objc_getAssociatedObject(self, &kHUDAttributes);
}

@end
