//
//  UIViewController+HUD.m
//  viralheat
//
//  Created by Rex Sheng on 10/11/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "UIViewController+HUD.h"
#import "MBProgressHUD+Appearance.h"

@implementation MBProgressHUD (Plist)

+ (NSDictionary *)configuration
{
	NSDictionary *attributes = [[self appearance] HUDAttributes];
	if (attributes) return attributes;
	static NSDictionary *conf;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString *path = [[NSBundle mainBundle] pathForResource:@"HUD" ofType:@"plist"];
		conf = [NSDictionary dictionaryWithContentsOfFile:path];
	});
	return conf;
}

@end

@implementation UIViewController (HUD)

- (void)displayHUD:(NSString *)text
{
	if (text) {
		MBProgressHUD *hud = [self HUD];
		NSDictionary *conf = [[hud class] configuration];
		NSNumber *square = conf[HUDAttributeSquare];
		if (square) hud.square = [square boolValue];
		BOOL uppercase = [conf[HUDAttributeUppercase] boolValue];
		text = NSLocalizedString(text, nil);
		if (uppercase) hud.labelText = text.uppercaseString;
		else hud.labelText = text;
		id image = conf[HUDAttributeCustomImage];
		if (image) {
			hud.mode = MBProgressHUDModeCustomView;
			if ([image isKindOfClass:[NSString class]]) image = [UIImage imageNamed:image];
			hud.customView = [[UIImageView alloc] initWithImage:image];
		} else {
			hud.mode = MBProgressHUDModeIndeterminate;
		}
	}
}

- (void)hideHUD:(BOOL)animated
{
	[MBProgressHUD hideAllHUDsForView:self.view animated:animated];
}

- (MBProgressHUD *)HUD
{
	MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
	if (!hud) {
		hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
		hud.removeFromSuperViewOnHide = YES;
		NSDictionary *conf = [[hud class] configuration];
		id fontName = conf[HUDAttributeLabelFont];
		if (fontName) {
			if ([fontName isKindOfClass:[UIFont class]]) {
				hud.labelFont = fontName;
			} else {
				BOOL iPad  = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
				CGFloat size = 0;
				if (iPad) size = [conf[@"labelFont.size_iPad"] floatValue];
				if (!size) size = [conf[@"labelFont.size"] floatValue];
				hud.labelFont = [UIFont fontWithName:fontName size:size];
			}
		}
		id detailFontName = conf[HUDAttributeDetailsLabelFont];
		if (detailFontName) {
			if ([detailFontName isKindOfClass:[UIFont class]]) {
				hud.detailsLabelFont = detailFontName;
			} else {
				BOOL iPad  = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
				CGFloat size = 0;
				if (iPad) size = [conf[@"detailsLabelFont.size_iPad"] floatValue];
				if (!size) size = [conf[@"detailsLabelFont.size"] floatValue];
				hud.detailsLabelFont = [UIFont fontWithName:fontName size:size];
			}
		}
		NSNumber *margin = conf[HUDAttributeMargin];
		if (margin) hud.margin = [margin floatValue];
	}
	return hud;
}

- (void)displayHUDError:(NSString *)title message:(NSString *)message
{
	MBProgressHUD *hud = [self HUD];
	hud.square = NO;
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideHUD:)];
	[hud addGestureRecognizer:tap];
	hud.mode = MBProgressHUDModeText;
	NSDictionary *conf = [[hud class] configuration];
	BOOL uppercase = [conf[HUDAttributeUppercase] boolValue];
	if (uppercase) {
		hud.labelText = NSLocalizedString(title, nil).uppercaseString;
		hud.detailsLabelText = NSLocalizedString(message, nil).uppercaseString;
	} else {
		hud.labelText = NSLocalizedString(title, nil);
		hud.detailsLabelText = NSLocalizedString(message, nil);
	}
	[hud hide:YES afterDelay:3];
}

@end
