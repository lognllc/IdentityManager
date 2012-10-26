//
//  UIViewController+HUD.m
//  viralheat
//
//  Created by Rex Sheng on 10/11/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "UIViewController+HUD.h"
#import "MBProgressHUD.h"
#import <objc/runtime.h>

@implementation MBProgressHUD (Plist)

+ (NSDictionary *)configuration
{
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
		NSNumber *square = conf[@"square"];
		if (square) hud.square = [square boolValue];
		BOOL uppercase = [conf[@"uppercase"] boolValue];
		text = NSLocalizedString(text, nil);
		if (uppercase) hud.labelText = text.uppercaseString;
		else hud.labelText = text;
		NSString *image = conf[@"custom.image"];
		if (image) {
			hud.mode = MBProgressHUDModeCustomView;
			hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:image]];
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
		NSString *fontName = conf[@"labelFont.name"];
		BOOL iPad  = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
		
		if (fontName) {
			CGFloat size = 0;
			if (iPad) size = [conf[@"labelFont.size_iPad"] floatValue];
			if (!size) size = [conf[@"labelFont.size"] floatValue];
			hud.labelFont = [UIFont fontWithName:fontName size:size];
		}
		fontName = conf[@"detailsLabelFont.name"];
		if (fontName) {
			CGFloat size = 0;
			if (iPad) size = [conf[@"detailsLabelFont.size_iPad"] floatValue];
			if (!size) size = [conf[@"detailsLabelFont.size"] floatValue];
			hud.detailsLabelFont = [UIFont fontWithName:fontName size:size];
		}
		NSNumber *margin = conf[@"margin"];
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
	BOOL uppercase = [[MBProgressHUD  configuration][@"uppercase"] boolValue];
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
