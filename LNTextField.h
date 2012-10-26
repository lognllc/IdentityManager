//
//  LNTextField.h
//
//  Created by Rex Sheng on 9/5/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LNTextField : UITextField

@property (nonatomic) CGFloat edgeInsetX;
@property (nonatomic, strong) UIImage *clearImage;
@property (nonatomic) CGFloat placeholderAlpha;
@property (nonatomic, readonly) NSString *safeText;

- (void)cleanUp;

@end
