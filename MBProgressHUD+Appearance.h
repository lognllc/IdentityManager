//
//  MBProgressHUD+Appearance.h
//
//  Created by Rex Sheng on 11/28/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "MBProgressHUD.h"

extern NSString * const HUDAttributeSquare;
extern NSString * const HUDAttributeUppercase;
extern NSString * const HUDAttributeCustomImage;
extern NSString * const HUDAttributeLabelFont;
extern NSString * const HUDAttributeDetailsLabelFont;
extern NSString * const HUDAttributeMargin;

@interface MBProgressHUD (Appearance)

@property (nonatomic, strong) NSDictionary *HUDAttributes UI_APPEARANCE_SELECTOR;

@end
