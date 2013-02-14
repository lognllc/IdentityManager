//
//  UIViewController+HUD.h
//
//  Created by Rex Sheng on 10/11/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (HUD)

- (void)displayHUD:(NSString *)text;
- (void)hideHUD:(BOOL)animated;
- (void)displayHUDError:(NSString *)title message:(NSString *)message;

@end
